# Aggregated API

`API` 服务聚合器，能够动态的注册不同的 `API` 服务器，并通过安全的代理机制提供访问

### 案例

通过 `APIService` 对象动态的往 `kube-apiserver` 上注册服务

[demo](../../../config/example/service/aggregate/demo.yaml)

对象创建成功之后进行访问 `/apis/{apiService.Spec.Group}/{apiService.Spec.Version}`

后端服务需要以 `Service` 服务暴露

### 创建

`kub-apiserver` 实际上是由三个 `apiserver` 组成，通过代理关联，`kube-apiserver` 创建流程

- 创建 `APIExtensionsServer`
  - `DelegationTarge` 为一个空的代理，它是代理的最后一环，如果处理不了就无法处理了
- 将 `APIExtensionsServer` 的 `GenericAPIServer`，作为 `delegationTarget` 创建 `KubeAPIServer`
- 将 `KubeAPIServer` 的 `GenericAPIServer` 创建 `AggregatorServer`

### 手脚架

`apiserver-builder` 官方工具

### CRDs

两者可以提供类似的功能，使用的新资源不多的情况下使用 `CRD` 比较简单


