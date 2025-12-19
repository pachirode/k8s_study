# Pod

### 多容器模式

- 边车模式
    - 主容器和辅助容器协作
- 大使模式
    - 代理容器处理外部通信
- 适配器模式
    - 转换容器输入格式

##### 边车模式

常见的 `Pod` 设计模式，在同一个 `Pod` 内运行主应用容器的同时，配套部署一个或多个辅助容器

```yaml
# 示例：Web 应用 + 日志收集器
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: web-app
      image: nginx
    - name: log-collector
      image: fluentd
```

##### 代理模式

- `API` 网关和后端服务
- 缓存代理和应用服务器
- 安全代理和业务容器

##### 适配器模式

- 监控数据格式转换
- 配置文件标准化
- 协议转换和桥接

### Pod 控制器

`k8s` 通过控制器来管理 `Pod`，实现自动化运维和弹性伸缩

##### 常见控制器

- `Deployment`
    - 无状态应用，副本管理和滚动更新
- `StatefulSet`
    - 有状态应用，有序部署和持久化存储
- `DaemonSet`
    - 节点级服务，每一个节点运行一个 `Pod`
- `Job`
    - 批处理任务，一次性任务执行
- `CronJob`
    - 定时任务，按计划执行任务

### Pod 扩缩容

`k8s` 中称为副本，控制器自动管理副本数量，实现弹性伸缩

##### Pod 模板

定义 `Pod Template`，可以嵌入各种控制器中，实现批量自动化管理
控制器使用模板来创建和管理 `Pod` 实例

### Pod 网络和存储

提供独立的网络和存储环境

##### 网络

- 每一个 `Pod` 拥有唯一的集群 `IP` 地址
- `Pod` 内容器共享网络命名空间
- 容器之间通过 `localhost` 通信
- 跨 `Pod` 通信需要通过 `Service`

##### 存储

- 支持多种卷类型
    - `EmptyDir`
    - `HostPath`
    - `PVC`
- 卷的生命周期和 `Pod` 一致
- 容器重启时数据保持不变
- `Pod` 删除时临时卷被清理

### Pod 终止流程

- 发起删除请求
    - 用户或者控制器请求删除 `Pod`
- 标记终止状态
    - `API Server` 更新 `Pod` 状态为 `Terminating`
- 执行预停止钩子
    - 运行 `preStop` 生命周期钩子
- 发送 `SIGTERM` 信号
    - 通知容器进程准备关闭
- 等待优雅的停止
- 强制终止
    - 发送 `SIGKILL` 信号强制停止进程
- 清理资源
    - 从 `API Server` 中移除 `Pod` 记录

##### 自定义终止行为

通过自定义 `Pod` 终止行为实现更加优雅的下线流程

```yaml
apiVersion: v1
kind: Pod
spec:
  terminationGracePeriodSeconds: 60  # 自定义优雅期
  containers:
    - name: app
      image: myapp
      lifecycle:
        preStop: # 容器被终止之前执行清理脚本
          exec:
            command: [ "/bin/sh", "-c", "cleanup.sh" ]
```

### 高级特性

##### 安全上下文

```yaml
apiVersion: v1
kind: Pod
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
  containers:
    - name: app
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop:
            - ALL
```

##### 资源管理

合理设置资源请求和限制，可以防止资源争用

