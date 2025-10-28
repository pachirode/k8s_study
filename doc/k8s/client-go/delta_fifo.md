控制器需要持续监控资源状态，使用本地缓存资源资源对象
`DeltaFIFO` 就是用来存储对象变更历史的队列，通过生产者消费者机制，实现了事件的处理

### Store 接口

使用唯一标识使得对象和键相关联，`KeyFunc` 主要就是用来提取唯一标识的
`KeyFunc` 的默认实现是，判断对方是否有命名空间，有提取 `name/name`，如果没有提取 `name`

- `Add`
- `Update`
- `Delete`
- `List`
- `ListKeys`
- `Get`
- `GetByKey`
- `Replace`
- `Resync`

##### Cache 实现

组合 `ThreadSafeStore` 和 `KeyFunc`，提供线程安全的对象存储
所有操作使用相同模式，先通过 `KeyFunc` 获取对象的键，然后操作 `ThreadSafeStore`
`ThreadSafeStore` 本身是一个 `Map`

### Queue 接口

扩展基础的 `Store` 接口，增加队列操作

##### FIFO

通过 `map + slice` 构造，`map` 提供查找，`slice` 记录元素先后顺序
创建时需要明确的传入 `KeyFunc`，不同的资源各自维护不同的 `FIFO`

- `Queue`
    - `objKey1`
    - `objKey2`
- `Items`
    - `objKey1:obj1`
    - `objKey2:obj2`

对象被更新 `Queue` 中的键不会重复添加，每次获取的都是该对象的最新状态，实现了即使对象在队列中等待，也可以被更新到最新的状态
对象被删除，会从 `Items` 中被删除

### UndeltaStore 接口

该接口不关心变化本身，每次都提供完整的状态
所有操作，都是先更新底层 `Store`，然后调用 `PushFunc` 传递完整状态

- 组合 `Store` 接口
- `PushFunc func([]interface{})`
    - 每次收到一组对象，而不是单单变化的那个

### Heap优先级队列

使用到优先级的场景，控制器决定那个资源先处理

### ExpirationCache

当获取对象时判断对象是否过期，如果过期从存储中删除，返回对象不存在

- `ExpirationPolicy` 接口
    - 定义了何时认为一个对象已经过期

### DeltaFIFO

记录完整的修改历史， `Delta` 可以当作是一个快照，`Deltas` 按时间顺序保存了一个对象所有变化记录
不同对象通过 `DeltaFIFO` 来控制和管理

- `Delta struct`
    - `Type   DeltaType`
        - 变化类型，添加更新删除
    - `Object`
        - 变化之后的对象

`queueActionLocked` 将事件类型和对象记录到队列中，每次修改对象之后会调用
该方法会进行查重操作，主要判断最近的两次操作是否重复，去重操作会保留状态信息更完整的

`Delta` 事件被存储到 `DeltaFIFO` 队列中，只有一个直接的消费者 `HandleDelta` 方法
- 更新 `Indexer` 存储
  - 根据事件的类型，调用方法来更新缓存
- 将事件分发给处理器