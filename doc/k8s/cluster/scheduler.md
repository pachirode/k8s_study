# kube-scheduler

`k8s` 集群负责 `Pod` 调度的核心组件

- 监听 `kube-apiserver` 中未调度的 `Pod`
- 根据调度算法为 `Pod` 选择合适的节点
- 通过预选和优选两个阶段完成调度决策

### 调度流程

- 预选阶段
    - 过滤掉不满足 `Pod` 运行条件的节点
- 优选阶段
    - 对候选节点进行评分，选择最优节点
- 绑定阶段
    - 将 `Pod` 分配到选定的节点

##### 调度策略

- `Deployment`
    - 分本分散调度
- `DaemonSet`
    - 每个节点运行一个 `Pod` 副本
- `StatefulSet`
    - 有序调度

