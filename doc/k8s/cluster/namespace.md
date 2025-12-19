# Namespace

用于同一个物理集群中创建多个虚拟的集群环境

### 使用场景

- 环境隔离
    - 将开发、测试、预生产和生产环境部署在不同的命名空间中
- 团队隔离
- 资源配额管理
- 权限控制

### 默认命名空间

- `default`
    - 用户默认部署位置
- `kube-system`
    - 系统组件的部署位置
- `kube-public`
    - 所有用户都可以访问的公共资源
- `kube-node-lease`
    - 节点心跳检测的租约对象

### 作用域

- `Namespace` 作用域
    - `Pod`
    - `Service`
    - `Deployment`
    - `ConfigMap`
    - `Secret`
    - `PersistentVolumeClaim`
- 集群作用域
    - `Node`
    - `PersistentVolume`
    - `StorageClass`
    - `ClusterRole`
    - `Namespace`

### 配额和限制

在多团队和多租户场景下，合理的分配和限制 `Namespace` 的资源很关键

- `ResourceQuota`
    - 限制 `Namespace` 内所有资源对象的总量
        - `Pod` 数量
        - `CPU` 数量
        - `PVC` 数量
- `LimitRange`
    - 为单个 `Pod` 或容器设置默认和最大最小资源
        - `request`
        - `limit`

##### ResourceQuota

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-resources
  namespace: dev
spec:
  hard:
    pods: "20"
    requests.cpu: "10"
    requests.memory: 40Gi
    limits.cpu: "20"
    limits.memory: 80Gi
```

### LimitRange

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: mem-limit-range
  namespace: dev
spec:
  limits:
    - default:
        memory: 2Gi
        cpu: 1
      defaultRequest:
        memory: 512Mi
        cpu: 0.2
      type: Container
```

