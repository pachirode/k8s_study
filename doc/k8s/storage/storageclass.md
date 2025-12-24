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

# 多集群

`k8s` 设计之初用于管理单个集群内的容器化负载，实际情况下会部署单个集群

- 高可用
    - 一个集群故障，其他集群可以继续对外服务
- 隔离性
- 扩展性
    - 突破单集群节点数量和资源上限
- 多云和混合云
- 边缘计算
    - 靠近用户或设备侧运行轻量集群

### 多集群可以遇到的问题

- 网络连通性
    - 跨集群服务通信，`DNS` 解析和流量调度
- 身份和访问控制
- 配置一致性和策略下发
- 应用部署和生命周期管理
    - 如何在多个集群中保证一致性
- 可观测和故障诊断
    - 需要统一的监控，日志追踪
- 成本和资源优化
    - 多集群增加资源分散

### 多集群架构模式

##### 独立集群模式

`Isolated Clusters` 每个集群独立运行，独立管理，适用于环境隔离，业务边界清晰的场景

##### 主控集群模式

一个主集群负责集中管理和调度多个从集群，通过控制面统一治理

##### 联邦模式

多个集群在逻辑上组成统一整体，通过标准化 `API` 共享配置和资源
实现和运维复杂度搞，适用于强一致性的场景

##### 混合模式

结合上述模式

### 多集群管理的核心功能

- 集群的注册和生命周期的管理
    - 支持动态加入，删除，升级和健康审查
- 集中身份认证和授权
    - 统一用户和服务账户体系，简化权限管理
- 策略治理
    - 集中分发安全，网络，资源等策略
- 应用分发和一致性控制
    - 基于声明式模型在多个集群之间保持应用同步
        - `GitOps`
- 跨集群网络和服务发现
    - 实现跨集群流量负载均衡，`DNS`
- 可观测性和审计

### 实现

- 基础设施层
    - 解决集群间的连接和通信
- 控制平面
    - 实现多集群资源注册、同步和策略控制
- 应用和工作负载层
    - `GitOps` `Service Mesh` 统一服务目录等方式，实现多集群之间的分发和运行应用
