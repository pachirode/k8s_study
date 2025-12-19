# Init 容器

运行在 `Pod` 中的特殊容器，在应用容器启动之前依次执行，用于完成初始化任务，每个 `Pod` 可以包含多个 `Init` 容器

### 特性

- 顺序执行，运行至完成
    - 多个 `Init` 容器按照定义顺序依次执行
    - 必须上一个容器执行完成，下一个才能启动
    - 所有 `Init` 容器成功之后，应用容器才能开始启动
- 失败时重启整个 `Pod`
- 不支持 `readinessProbe` 探针
- 一次性执行

### 使用场景

- 依赖服务检查
    - 等待数据库，缓存等依赖服务就绪
- 数据预处理
    - 下载配置文件，生成动态配置
- 权限和安全设置
    - 修改文件权限，创建用户，设置证书
- 资源准备
    - 初始化数据库，安装依赖包

# Puase 容器

为 `Pod` 内的所有业务容器提供统一的命名空间基础

### 容器特点

- 轻量级
    - 容器极小
- 持久运行
    - 容器始终处于暂停状态
- 支持多种架构
- 几乎不消耗资源

### 网络共享

- 创建 `Pause` 容器
- 业务容器通过 `--net=container:pause` 加入同一个 `Network Namespace`
- 所有容器共享 `IP`、端口、路由表等网络资源

### 职责

- 命名空间共享
- `Init` 进程角色
    - 作为 `Pod` 内 `PID 1`，负责回收僵尸进程和信号处理

# Sidecar

指的是与主容器共同运行在同一个 `Pod` 内的辅助容器

- 共享资源
- 松耦合
- 透明性
- 可重用性

### 日志收集

将主容器日志转发到日志系统，主容器与日志收集 `Sidecar` 通过共享卷实现日志文件共享

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-sidecar
spec:
  containers:
    - name: app
      image: my-app:latest
      volumeMounts:
        - name: shared-logs
          mountPath: /var/log
    - name: log-collector
      image: fluent/fluent-bit:latest
      volumeMounts:
        - name: shared-logs
          mountPath: /var/log
  volumes:
    - name: shared-logs
      emptyDir: { }
```

### 服务网格代理

在服务网格中，`Sidecar` 容器作为代理，部署于每个应用 `Pod` 内，实现流量管理等功能

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-proxy
spec:
  containers:
    - name: app
      image: my-app:latest
      ports:
        - containerPort: 8080
    - name: envoy-proxy
      image: envoyproxy/envoy:latest
      ports:
        - containerPort: 9901
```

### 配置热更新

监听 `ConfigMap` 变化，实现配置热更新，无需重启主容器

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-config-watcher
spec:
  containers:
    - name: app
      image: my-app:latest
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config
    - name: config-watcher
      image: config-watcher:latest
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        name: app-config
```
