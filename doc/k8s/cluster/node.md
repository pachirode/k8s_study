# Node

集群资源管理的基础环节，负责运行 `Pod` 和容器化应用的基础计算单元
每个节点可以是物理服务器或虚拟机

### 状态

- 地址
    - `HostName`
        - 节点主机名
    - `ExternalIP`
        - 节点外部可路由访问 `IP` 地址
    - `InternalIP`
        - 集群内部通信使用的 `IP` 地址，外部无法直接访问
- 节点条件
    - 反应节点的健康和可调度状态
        - `Ready`
            - 节点是否准备就绪，接受 `Pod` 调度
        - `MemeoryPressure`
            - 节点内存资源是否紧张
        - `DiskPressure`
            - 节点磁盘空间是否不足
        - `PIDPressure`
            - 节点进程数接近限制
        - `NetworkUnavailable`
            - 节点网络配置是否正常
- 容量信息
    - `Pod`
    - `Memeory`
    - `Pods`
    - `Storage`
- 节点信息
    - 系统和组件版本

### 命令

```bash
# 需要维护节点或避免新的 Pod 调度
kubectl cordon <node-name>
kubectl uncordon <node-name>

# 安全的将 Pod 迁移到其他节点
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```
