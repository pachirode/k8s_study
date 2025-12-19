# CSI

一个行业标准接口规范，统一容器编排系统和存储系统之间的交互方式
作为 `out-of-tree` 插件实现，意味着可以和核心代码分离，独立开发、测试

### Controller 组件

- `CSI Controller`
    - 负责卷的生命周期管理
- `External-provisioner`
    - 监听 `PVC`，触发卷的创建和删除
- `External-attacher`
    - 处理卷的挂载和卸载操作
- `External-resizer`
    - 处理卷的扩容操作

### Node 组件

- `CSI Node`
    - 在每个节点上运行，负责卷的挂载和具体路径
- `Node-driver-registrar`
    - 向 `kubelet` 注册 `CSI` 驱动程序

### 配置

##### 动态配置

通过 `StorageClass` 实现卷的动态创建

##### 静态配置

手动创建 `PV`

##### Pod 使用 CSI 卷

`Pod` 通过 `PVC` 的方式挂载 `CSI` 卷

### CSI 驱动程序

##### 实现 CSI 接口

- `Identity Service`
    - 提供驱动程序身份信息
- `Controller Service`
    - 管理卷的生命周期
- `Node Service`
    - 处理节点级别的卷操作

##### Sidecar 容器

- `external-provisioner`
    - 监听 `PVC` 事件
- `external-attacher`
    - 监听 `VolumeAttachment` 事件
- `external-resizer`
    - 处理 `PVC` 扩容
- `external-snapshotter`
    - 管理卷快照
- `node-driver-registrar`
    - 向 `kubelet` 注册 `CSI` 驱动
- `livenessprobe`
    - 监控 `CSI` 驱动监控状态

### 功能

##### 卷快照

`CSI` 支持卷快照功能，允许用户创建卷的时间点副本

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: my-snapshot
spec:
  volumeSnapshotClassName: csi-snapclass
  source:
    persistentVolumeClaimName: app-storage-claim
```

##### 卷克隆

支持从现有的 `PVC` 克隆新的卷

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cloned-pvc
spec:
  dataSource:
    name: app-storage-claim
    kind: PersistentVolumeClaim
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

##### 卷扩容

支持在线扩容已挂载的卷

### 调试命令

```bash
# 查看 CSI 驱动程序状态
kubectl get csidrivers

# 查看 CSI 节点信息
kubectl get csinodes

# 查看卷挂载状态
kubectl get volumeattachments

# 查看存储类
kubectl get storageclass
```

