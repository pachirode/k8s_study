# Taint 和 Toleration

污点和容忍机制为 `k8s` 提供了灵活的节点隔离和调度控制能力，是实现多租户和资源的专用场景
和亲和性不同，这个是排他性机制

### 工作机制

`Taint` 和 `Toleration` 互相配合，决定 `Pod` 是否能被调度到某个节点

- `Node Taint`
    - 节点可以设置一个或者多个 `Taint`，表示节点无法容忍这些 `Pod`
- `Pod Toleration`
    - 通过配置 `Toleration`，可以容忍特定的 `Taint`，从而允许调度这些带有污点的节点

### 设置 Taint

```bash
# 禁止调度新 Pod
kubectl taint nodes node1 key1=value1:NoSchedule
# 删除
kubectl taint nodes node1 key1:NoSechedule-

# 驱逐现有 Pod 并禁止调度新 Pod
kubectl taint nodes node1 key1=value1:NoExecute

# 尽量避免调度（软限制）
kubectl taint nodes node1 key2=value2:PreferNoSchedule
```

### 设置 Toleration

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example-pod
spec:
  tolerations:
    - key: "key1"
      operator: "Equal"
      value: "value1"
      effect: "NoSchedule"
    - key: "key1"
      operator: "Equal"
      value: "value1"
      effect: "NoExecute"
      tolerationSeconds: 3600
    - key: "maintenance"
      operator: "Exists"
      effect: "NoExecute"
      tolerationSeconds: 300
  containers:
    - name: app
      image: nginx
```

### 常见使用场景

##### 专用节点

为特定工作负载预留节点

```bash
# 标记节点为 GPU 专用
kubectl taint nodes gpu-node dedicated=gpu:NoSchedule
```

##### 节点临时维护

##### 问题节点处理

### 内置污点

`k8s` 会自动为节点添加一些内置污点，用于反映节点健康和资源状态

- `node.kubernetes.io/not-ready`
    - 节点未就绪
- `node.kubernetes.io/unreachable`
    - 节点不可达
- `node.kubernetes.io/memory-pressure`
- `node.kubernetes.io/pid-pressure`
- `node.kubernetes.io/network-unavailable`

