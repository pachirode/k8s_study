# StorageClass

为管理员提供描述存储类的方法，不同的类可以对应不同等级的策略
该机制被称为存储配置文件或者存储策略

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd # StorageClass 名称，通过此名称引用
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: kubernetes.io/gce-pd # 指定用于动态创建 PV 的存储分配器
parameters: # 传递给分配器参数，根据分配器确定
  type: pd-ssd
  replication-type: regional-pd
reclaimPolicy: Delete # 回收策略
allowVolumeExpansion: true # 是否允许扩容
mountOptions: # 卷挂载选项
  - debug
  - noatime
volumeBindingMode: WaitForFirstConsumer # 卷绑定模式
```

### 存储分配器

决定如何创建和管理持久卷

##### 内置分配器

##### CSI 分配器

##### 外部分配器

- `NFS`
- `Longhorn`
- `OpenEBS`

### 默认 StorageClass

集群可以设置一个默认 `StorageClass`，供未指定 `storageClassName` 的 `PVC` 使用

