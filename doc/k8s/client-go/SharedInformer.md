使得 `Reflector`，`DeltaFIFO` 和 `Indexer` 组件相互协作
主要用来解决在分布式环境下，如何让多个客户端高效的获取资源状态
通过共享同一个缓存和 `List+Watch` 避免重复的 `API` 调用，当资源发生变化时，同时通知给所有注册的监听器

- 数据缓存
    - 管控上述组件，提供本地缓存
- 事件分发
    - 资源对象发生变化时，将变化事件分发给注册的事件处理器

### SharedInformer 接口

- `AddEventHandler`
    - 事件处理注册
- `AddEventHandlerWithResyncPeriod`
    - 同步周期的事件处理能力
- `GetStore`
    - 本地缓存访问
- `Run`
- `HasSynced`
- `LastSyncResourceVersion`
- `SetWatchErrorHandler`

##### 步骤

当 `DeltaFIFO` 队列中有变化，会调用 `HandleDeltas` 方法来处理这些变化

- 更新本地缓存 `Indexer`
- 将事件分发给所有注册的监听器

##### SharedInformerFactory

以资源类型为 `key`，`SharedInformerFactory` 为 `value`，确保一个资源类型只有一个 `Informer`