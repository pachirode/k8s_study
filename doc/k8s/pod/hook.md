# Pod Hook

让容器在关键的生命周期节点自动执行自定义逻辑，`Hook` 在容器启动后或者终止前运行，执行自定义逻辑

### Hook 类型

##### Exec Hook

用于在容器内执行命令或脚本，常用于初始化或清理

```yaml
lifecycle:
  postStart:
    exec:
      command: [ "/bin/sh", "-c", "echo 'Container started' > /tmp/started" ]
```

##### HTTP Hook

用于向指定端点发送 `HTTP` 请求，适合与外部服务集成

```yaml
lifecycle:
  preStop:
    httpGet:
      path: /shutdown
      port: 8080
      scheme: HTTP
```

### Hook 事件

`Pod Hook` 包含两个关键事件，分别在容器启动和终止时触发

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-demo
spec:
  containers:
    - name: lifecycle-demo-container
      image: nginx:1.21
      lifecycle:
        postStart:
          exec:
            command: [ "/bin/sh", "-c", "echo 'Hello from postStart' > /usr/share/message" ]
        preStop:
          httpGet:
            path: /api/shutdown
            port: 80
            scheme: HTTP
  terminationGracePeriodSeconds: 60
```

##### PostStart Hook

- 容器创建之后立即执行
- 与容器主进程异步运行
- 需要等待 `postStart` 完成之后才能将容器设为 `RUNNING`
- 主要用于初始化配置，注册服务等

##### PreStop Hook

- 容器终止前执行
- 同步阻塞调用
- 默认 30 秒
- 主要用于关停，清理资源

