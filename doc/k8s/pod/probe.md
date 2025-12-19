# 容器探针(Probes)

探针是 `kubelet` 对容器执行的定期健康检查，通过调用容器实现的处理程序来执行判断

### 探针类型

- `ExecAction`
    - 执行指定命令
- `TCPSocketAction`
    - `TCP` 端口检查
- `HTTPGetAction`
    - `HTT Get` 请求
- `Liveness Probe`
    - 存活探针
        - 检测容器是否正在运行
        - 失败时 `kubelet` 杀死容器，按照重启策略处理
        - 不设置默认为 `Success`
- `Readiness Probe`
    - 就绪探针
        - 检测容器是否准备好接收流量
        - 失败时从 `Service` 端点移除 `Pod IP`
        - 未配置时默认 `Success`
- `Startup Probe`
    - 启动探针
        - 检测容器是否已经启动
        - 启动探针成功前，其他探针被禁用
        - 适用于慢启动应用，启动时间比较长

### 就绪门控

在 `PodSpec` 中设置 `readinessGates`，指定额外的就绪条件


