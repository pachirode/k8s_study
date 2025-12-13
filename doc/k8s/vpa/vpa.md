# VPA

垂直 `Pod` 自动扩缩容，根据容器资源使用率自动设置 `CPU` 和内存的 `requests`，以便为每个 `Pod` 提供适当的资源

组件
- `VPA Controller`
  - `Recommender`
    - 给出 `pod` 资源调整建议
  - `Updater`
    - 对比建议值和当前值，不一致时驱逐 `Pod`
- `VPA Admission Controller`
  - `Pod` 重建时将 `Pod` 资源请求量修改为推荐值

### 流程

[流程](./flow.puml)

##### Recommender

根据应用当前的资源使用情况和历史情况，计算接下来的资源阈值，如何计算的值和当前的不一致，提出一条资源调整建议

##### Updater

根据这些建议进行调整
- 发现需要调整的，调用 `api` 驱逐 `Pod`
- `Pod` 被驱逐之后会重建
- `VPA Admission Controller` 拦截重建，根据 `Recommend` 调整资源
- 调整完继续重建步骤

### 案例

需要保证安装 `Openssl`

[Metrics Server](../../../config/example/vpa/metrics-server.yaml) 负责提供指标信息，需要先在集群中安装

```bash
kubectl get apiservice | grep metrics
v1beta1.metrics.k8s.io            kube-system/metrics-server   True        20s


```