# Volume

属于 `Pod` 内部共享资源，生命周期和 `Pod` 相同
这样的存储无法满足有状态要求，`Persistent Volume` 独立于 `Pod` 的资源，一种网络存储

### 挂载

- 远程存储挂载到宿主机，只有远程存储才会执行，对应 `PV api`
    - `Attach`
        - 由控制器执行，将远程磁盘挂载到宿主机
    - `Mount`
        - 由 `kubectl` 远程磁盘格式化并挂载到 `Volume` 对应的宿主机目录 `/var/lib/kubelet`
- 宿主机目录挂载到 `Pod`
    - `CRI` 执行

[流程](./flow.puml)

##### Attach

由 `AttachDetachController + external-attacher` 完成

`ADController` 不断检查 `Pod` 对应的 `PV` 和所在宿主机之间的挂载情况，从而决定 `Attach` 还是 `Dettach`

`external-attacher` 检测到上一步创建的 `VolumeAttachment` 对象，如果 `CSI Plugin` 在同一个 `Pod`
，调用接口进行 `Volume Attach`

##### Mount

由 `VolumeManagerReconciler` 完成

检测到有新使用的 `PV` 调度到节点上，进行相关处理
将硬盘格式化并挂载到宿主机目录

##### CRI 将 Volume 挂载到 Pod

### 概念

- `PV`
    - 持久化存储卷
- `PVC`
    - `PV` 使用请求
- `StorageClass`
    - `PV` 创建模板

[hostpath](../../../config/example/volume/hostpath.yaml)
[ceph](../../../config/example/volume/ceph.yaml)

### 使用

##### PV

存储卷，存储系统的一个存储空间对应一个 `PV`

[demo](../../../config/example/volume/pv.yaml)

需要专业的存储知识，一般由运维人员负责

状态
- `Recycle(deprecatedc)`
  - 弃用，删除 `pvc`，只删除 `pv` 数据不删除资源
- `Delete`
  - 同时删除资源
- `Retain`
  - 不删除

##### PVC

`PV` 注册，请求占用 `PV` 到 `Pod` 命名空间
一个 `PVC` 可以绑定一个 `PV`，该 `pv` 处于 `bingding`，一个命名空间占用一个 `PV`

访问模式

- 单路读写
- 多路读写
- 多路只读

[demo](../../../config/example/volume/pvc.yaml)

只需要指定访问模式和空间大小

##### StorageClass

关联 `PV` 和 `PVC`，只有 `StorageClass` 相同才会才会被绑定到一起
也可以作为 `PV` 模板，实现动态创建 `PV`

`Dynamic Provisioning` 机制，根据 `PVC` 和 `StorageClass` 自动创建 `PV`

### 流程

##### 创建 `StorageClass` 和 `provisioner`

[storageClass](../../../config/example/volume/storage.yaml)

[provisioner](../../../config/example/volume/provisioner.yaml)

##### 创建 PV

[pv](../../../config/example/volume/pv-storage.yaml)

需要保证 `storageClassName` 和前面的 `StorageClass` 对应
`PersistentVolumeController` 会根据 `PVC` 寻找对应的 `PV` 进行绑定
`provisioner` 会监视 `PVC`，根据 `StorageClass` 找到对应 `provisioner` 进行处理，创建对应的 `PV`