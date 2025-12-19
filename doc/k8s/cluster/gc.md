# 垃圾回收机制

为了保证节点资源充足，`kubelet` 提供了 `Pod` 驱逐和垃圾回收机制来保证节点资源不被耗尽

- 节点资源不足时，会根据 `Qos` 优先级驱逐 `Pod`
- 清理不需要的容器和镜像

### 配置

使用两个 `goroutine` 实现垃圾回收功能

`kubelet` 默认开启垃圾回收功能，对容器进行垃圾回收的频率为每分钟一次，对镜像为五分钟一次

### 触发点

- 正常触发
    - 定时执行
- 强制触发
    - 节点资源不足

### 容器回收流程

- 清理可驱除的容器
- 清理可驱除的 `sandbox`
- 清理所有 `pod` 的日志目录

### 镜像回收流程

- 获取 `kubelet` 磁盘状态
- 计算磁盘总量和可用容量的使用百分比
- 如果使用率超过阈值就会执行垃圾回收
- 根据参数和当前使用率计算需要的空间
- 执行垃圾回收直到有充足的资源

### Owner 和 Dependent

`k8s` 中，对象之间存在所有权关系

- `Deployment`
    - `ReplicaSet`
- `ReplicaSet`
    - `Pod`
- `Service`
    - `Endpoints`
- `Job`
    - `Pod`
- `StatefulSet`
    - `Pod`

每个 `Dependent`  都有一个 `metadata.ownerReferences` 字段，指向 `Owner` 对象

##### ownerReference

用于描述当前对象和所有者之间的关系，`k8s` 能够自动的识别对象的归属关系，并在 `Owner`
被删除时，根据级联删除策略自动处理 `Dependent` 对象

```yaml
ownerReferences:
  - apiVersion: apps/v1
    kind: ReplicaSet
    name: my-repset
    uid: d9607e19-f88f-11e6-a518-42010a800195
    controller: true
    blockOwnerDeletion: true # 是否阻止 Owner 对象删除
```

##### 自动设置

`k8s` 在以下场景会自动设置 `ownerReference`

- 控制器管理的对象
- 服务发现相关
    - `Service` 创建的 `Endpoints` `Ingress`
- 存储相关
    - `PVC` 和 `PV` 之间的关系

### 级联删除策略

通过不同的级联删除策略控制 `Dependent` 对象处理方式

##### Background 级联删除

默认策略，适用于大部分场景，删除速度快，且不阻塞
主要用于清理日常资源

- 立即删除 `Owner` 对象
- 垃圾回收器在后台异步删除 `Dependent` 对象
- `Owner` 对象从 `API` 服务器中立即移除

##### Foreground 级联删除

顺序删除，确保完全清理
`Owner` 对象在删除工程总中可以继续通过 `API` 访问
确保子资源全部被删除

- `Owner` 对象进入删除中状态
- 设置 `deletionTimestamp`
- 添加 `foregroundDeletion` `finalizer`
- 等待所有 `Dependent` 对象删除完成
- 最后删除 `Owner` 对象

##### Orphan 策略

孤儿模式，保留子资源，用于需要保留子资源的场景

- 删除 `Owner` 对象
- 清空 `Dependent` 对象的 `ownerReferences` 字段
- 对象称为孤儿继续存在

### 高级特性

##### blockOwnerDeletion 机制

`blockOwnerDeletion` 字段控制是否阻止 `Owner` 对象删除，仅在 `Foreground` 删除模式下生效

```yaml
ownerReferences:
  - apiVersion: apps/v1
    kind: ReplicaSet
    name: my-repset
    uid: d9607e19-f88f-11e6-a518-42010a800195
    controller: true
    blockOwnerDeletion: true  # 阻止 Owner 删除
```

##### Finalizers

防止对象被删除的机制，用于资源保护和自定义清理逻辑

### 监控和查看

```bash
# 监控垃圾收集器状态
kubectl get events --field-selector reason=SuccessfulDelete

# 查看孤儿对象
kubectl get pods --all-namespaces -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,OWNER:.metadata.ownerReferences[0].name

# 检查长时间未删除的对象
kubectl get all --show-labels | grep deletionTimestamp
```

### 权限配置

确保垃圾回收器具有足够的权限，避免因为权限不足无法清理

```yaml
# gc-rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:gc-controller
rules:
  - apiGroups: [ "*" ]
    resources: [ "*" ]
    verbs: [ "list", "watch", "delete" ]
```

### 常见问题及解决方案

##### 对象无法删除

```bash
# 检查 finalizers
kubectl get <resource> <name> -o yaml | grep -A 5 finalizers

# 检查 blockOwnerDeletion
kubectl get <resource> <name> -o yaml | grep -A 10 ownerReferences
```

##### 删除时间过长

```bash
# 查看删除进度
kubectl get events --field-selector involvedObject.name=<name>

# 检查 Dependent 对象状态
kubectl get all -l <label-selector>
```

##### 孤儿对象累积

```bash
# 查找孤儿对象
kubectl get pods -o json | jq '.items[] | select(.metadata.ownerReferences == null)'

# 清理孤儿对象
kubectl delete pods -l <label-selector> --cascade=orphan
```

##### 调试命令

```bash
# 查看垃圾收集器日志
kubectl logs -n kube-system kube-controller-manager-<node-name> | grep garbage

# 查看对象删除历史
kubectl get events --sort-by='.lastTimestamp' | grep Delete

# 检查对象依赖关系
kubectl get <resource> <name> -o yaml | yq '.metadata.ownerReferences'
```