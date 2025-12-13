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

更新策略
- `Initial`
  - 仅在 `Pod` 创建时修改资源请求
- `Auto`
  - 默认策略，在 `Pod` 创建和更新都会修改资源请求
- `Recreate`
  - 类似 `Auto`，但是资源不匹配会驱逐 `Pod`，一般不使用
- `Off`
  - 不改变资源请求，可以设置

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

`Metrics Server` 负责提供指标信息，需要先在集群中安装

##### 安装 VPA

[参考链接](https://github.com/kubernetes/autoscaler/blob/master/vertical-pod-autoscaler/docs/installation.md)

```bash
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler/deploy
# sed -i 's/Always/IfNotPresent/g'  recommender-deployment.yaml
# sed -i 's/Always/IfNotPresent/g'  admission-controller-deployment.yaml
# sed -i 's/Always/IfNotPresent/g'  updater-deployment.yaml

cd autoscaler/vertical-pod-autoscaler/hack
./vpa-up.sh

kubectl get pods -n kube-system | grep vpa
vpa-admission-controller-795598f856-99hmd        1/1     Running   0               51s
vpa-recommender-5689665744-fzchw                 1/1     Running   0               52s
vpa-updater-6cf6bc7ff8-xqb2q                     1/1     Running   0               52s
```

##### 测试

[demo](../../../config/example/vpa_hpa/deploy-vpa-loop.yaml)

```bash
kubectl top pod
NAME                       CPU(cores)   MEMORY(bytes)   
hamster-699bd6fd88-8c7wq   514m         0Mi
hamster-699bd6fd88-ggk2s   514m         0Mi

```

