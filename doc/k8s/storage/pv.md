# PV

提供了一整套 `API`，将存储的实现细节从使用方式中抽象出来

`PV` 集群管理员预先配置或动态创建的存储资源，属于集群基础设施的一部分
`PVC` 用户对存储资源的请求声明，消耗 `PV` 资源
`StorageClass` 一种描述存储类别的机制

### 生命周期

##### 配置

- 静态配置
    - 管理员预先创建 `PV` 资源池，需要已有存储基础设施
- 动态配置
    - 静态 `PV` 无法满足需求，`StorageClass` 自动创建 `PV`

##### 绑定

控制平面持续监控新创建的 `PVC`，寻找匹配的 `PV` 并建立一对一的绑定关系，确保数据安全
如果未匹配到 `PV` 的 `PVC` 将保持 `Pending` 状态

- 存储容量满足需求
- 访问模式兼容
- `StorageClass` 匹配
- 标签选择器匹配

##### 使用

`Pod` 通过 `volume` 配置引用 `PVC` 使用持久化存储
调度器确保 `Pod` 被调度到能访问的对应存储的节点，`kubelet` 负责挂载存储卷

##### 存储对象保护

启用存储对象保护

- 正在使用的 `PVC` 不会被立即删除
- 绑定到 `PVC` 的 `PV` 受到保护
- 删除操作延迟到资源不再被使用时执行

##### 回收阶段

`PVC` 删除之后，`PV` 根据回收策略处理的

- `Retain`
- `Delete`
- `Recycle`

### PV 配置文件

##### 基础配置

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-nfs-example
  labels:
    type: nfs
    environment: production
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs-storage
  mountOptions:
    - hard
    - nfsvers=4.1
    - rsize=1048576
    - wsize=1048576
  nfs:
    path: /data/kubernetes
    server: nfs.example.com
```

##### 存储容量

定义 `PV` 的存储容量，目前主要支持存储大小

##### 访问模式

- `ReadWriteOnce`
    - 单节点读写
- `ReadOnlyMany`
    - 多节点只读
- `ReadWriteMany`
    - 多节点读写
- `ReadWriteOncePod`
    - 单 `Pod` 读写

##### 卷模式

- `Filesystem`
    - 以文件系统方式挂载
- `Block`
    - 以原始块设备方式使用

##### 节点亲和性

限制 `PV` 可挂载节点范围

```yaml
nodeAffinity:
  required:
    nodeSelectorTerms:
      - matchExpressions:
          - key: kubernetes.io/os
            operator: In
            values: [ "linux" ]
```

### PVC 配置

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: web-storage-claim
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 8Gi
    limits:
      storage: 10Gi
  storageClassName: fast-ssd
  selector:
    matchLabels:
      environment: production
    matchExpressions:
      - key: type
        operator: In
        values: [ ssd, nvme ]
```

##### 资源配置

- `requests`
    - 最小存储需求
- `limits`
    - 最大存储限制，部分存储类型支持

##### 选择器配置

通过标签选择器精确匹配 `PV`

```yaml
selector:
  matchLabels:
    environment: production
    tier: frontend
  matchExpressions:
    - key: type
      operator: NotIn
      values: [ slow-disk ]
```

### Pod 中使用持久化存储

`Pod` 可以通过 `volume` 或 `volumeDevice` 挂载 `PVC`

##### 文件系统模式

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-server
spec:
  containers:
    - name: nginx
      image: nginx:1.21
      volumeMounts:
        - name: web-content
          mountPath: /usr/share/nginx/html
          readOnly: false
  volumes:
    - name: nginx-config
      persistentVolumeClaim:
        claimName: nginx-config-claim
```

##### 块设备模式

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: database-pod
spec:
  containers:
    - name: database
      image: postgres:13
      volumeDevices:
        - name: db-storage
          devicePath: /dev/block-device
  volumes:
    - name: db-storage
      persistentVolumeClaim:
        claimName: database-block-claim
```

### StorageClass 配置

支持多种参数和策略，适配不同的存储后端和业务

##### 实例

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
reclaimPolicy: Delete
mountOptions:
  - debug
  - noatime
```

##### 卷绑定模式

- `Immediate`
    - `PVC` 创建之后立即绑定 `PV`
- `WaitForFirstConsumer`
    - 等待 `Pod` 调度之后再绑定（推荐）

### 主流插件

- `AWS`
    - `EBS`
    - `EFS`
    - `FSX`
- `Google Cloud`
    - `Persistent Disk`
    - `Filestore`
- `Azure`
    - `Disk`
    - `Files`

### 卷扩展

在 `StorageClass` 中启用卷扩展

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: expandable-storage
provisioner: ebs.csi.aws.com
allowVolumeExpansion: true
parameters:
  type: gp3
  encrypted: "true"
```

##### 扩展 PVC

直接编辑修改

##### 扩展限制

- 只能增加容量
- 某些 `Pod` 需要重启之后才能识别新容量
- 文件系统扩展需要时间
