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

`external-attacher` 检测到上一步创建的 `VolumeAttachment` 对象，如果 `CSI Plugin` 在同一个 `Pod`，调用接口进行 `Volume Attach`

##### Mount

由 `VolumeManagerReconciler` 完成

检测到有新使用的 `PV` 调度到节点上，进行相关处理
将硬盘格式化并挂载到宿主机目录

##### CRI 将 Volume 挂载到 Pod