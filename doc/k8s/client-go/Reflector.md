`Reflector` 通过 `List+Watch` 模式和 `API` 服务器保持高效的通信，可以通过 `Informer` 间接调用

主要功能

- `List + Watch` 和服务器交互
- 将获取到的数据更新到缓存中

### List + Watch 机制

- 实时接口
    - 请求量大会导致接口的响应速度和稳定性变差
- 缓存轮询
    - 实时性差
- `List + Watch`
    - 初始化获取一次完整数据
    - 建立长连接监听指定资源变化
    - 指定资源发生变化，立即更新缓存
    - 接口请求，直接返回缓存内容

### ResourceVersion

每个资源对象都有一个唯一的 `resourceVersion`，当资源变更时，会自动递增

- 如果上次 `resourceVersion` 不可用，返回空字符串，会触发 `etcd` 进行一致性读取
- 如果首次同步，返回 `0`，直接从 `Watch` 缓存中读取数据，否则返回上次同步到 `ResourceVersion`

### Bookmarks

如果一直 `Watch` 的资源很稳定，连接可能因为 `ResourceVersion` 过期而断开，需要重新 `List` 数据
`Bookmarks` 为了解决这个问题而产生的特殊事件，不包含实际资源数据，只取更新 `ResourceVersion`

### Informer 模式

`Reflector` 通常是作为 `Informer` 模式的一部分，在编写控制器或 `operator` 间接调用