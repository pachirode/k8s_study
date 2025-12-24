# ConfigMap

存储键值对配置数据

### 使用

- 环境变量
- 命令行参数
- 配置文件
- 应用配置

### 创建

- 目录创建
    - 当有多个配置文件时，可以通过目录批量创建
- 使用单个文件
- 使用字面值
- 使用 `yaml`

### Pod 中使用

##### 作为环境变量

使用单个值

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
    - name: app-container
      image: nginx:1.20
      env:
        - name: DATABASE_HOST
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: database.host
```

使用整个 `ConfigMap`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
    - name: app-container
      image: nginx:1.20
      envFrom:
        - configMapRef:
            name: app-config
```

命令行参数

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
    - name: app-container
      image: nginx:1.20
      command: [ "/bin/sh" ]
      args: [ "-c", "echo 'Database: $(DATABASE_HOST)'" ]
      env:
        - name: DATABASE_HOST
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: database.host
```

##### 数据卷

每一个键都会成为 `/etc/config/` 目录下的一个文件

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
    - name: app-container
      image: nginx:1.20
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        name: app-config
        defaultMode: 0644 # 设置文件权限
        items: # 挂载特定键
          - key: database.host
            path: db/host
```

### 热更新

##### 环境变量方式挂载

配置数据在 `Pod` 启动时被读取固定，无法支持运行时更新

##### Volume 方式挂载

`kubelet` 定期同步 `ConfigMap` 的变化到挂载的文件系统中

###### 使用 subPath 挂载可以不适用热更新

```yaml
# 不支持热更新的配置
volumeMounts:
  - name: config-volume
    mountPath: /etc/nginx/nginx.conf
    subPath: nginx.conf  # 使用 subPath 时不会热更新
```

###### 更新延迟

- `kubelet` 同步周期
- `configMap` 缓存周期
- 文件系统同步

##### 原子性保证

使用符号链接保证原子性更新

### 强制更新

对于不支持热更新的环境变量，可以强制触发配置更新

##### Deployment 滚动更新

通过修改 `Pod` 模板触发滚动更新

```bash
# 方法 1：添加时间戳注解
kubectl patch deployment configmap-env-demo -p \
  '{"spec":{"template":{"metadata":{"annotations":{"configmap/restart":"'$(date +%s)'"}}}}}'

# 方法 2：使用 kubectl rollout restart
kubectl rollout restart deployment/configmap-env-demo
```

###### Reloader 自动化工具

自动监控 `ConfigMap` 并触发相关 `Deployment` 重启

```yaml
# 在 Deployment 中添加注解
apiVersion: apps/v1
kind: Deployment
metadata:
  name: configmap-demo
  annotations:
    reloader.stakater.com/auto: "true"
    # 或者指定特定的 ConfigMap
    # configmap.reloader.stakater.com/reload: "my-configmap"
```
