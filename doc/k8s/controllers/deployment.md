# Deployment

为 `Pod` 和 `ReplicaSet` 提供声明式定义方法，是管理无状态应用的核心控制器

### 功能

- 创建管理
    - 创建 `Pod` 和 `ReplicaSet`
- 滚动更新
    - 支持应用的滚动升级和回滚
- 弹性伸缩
    - 支持应用的扩缩容
- 暂停控制
    - 可以暂停和继续 `Deployment` 的部署过程

### 常用操作命令

常见的 Deployment 运维命令如下：

```bash
# 扩容应用
kubectl scale deployment nginx-deployment --replicas 10

# 设置自动扩缩容
kubectl autoscale deployment nginx-deployment --min=10 --max=15 --cpu-percent=80

# 更新镜像
kubectl set image deployment/nginx-deployment nginx=nginx:1.21

# 回滚到上一版本
kubectl rollout undo deployment/nginx-deployment
```

### 更新

##### 监控更新状态

查看 rollout 状态：

```bash
kubectl rollout status deployment/nginx-deployment
```

##### 滚动更新过程

默认采用滚动更新，保证服务可用性

- `maxUnavailable`
    - 默认最多四分之一不可用
- `maxSurge`
    - 默认四分之一超出预期数量

##### 并行滚动更新

如果在更新过程中再次修改 `Deployment`，会立即创建新的 `ReplicaSet`，并终止之前的更新

##### 标签选择器更新

必须同步修改 `Pod template` 的 `label`，避免产生孤儿 `ReplicaSet`

### 案例

##### 金丝雀发布

```yaml
# 稳定版本
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-stable
spec:
  replicas: 9
  selector:
    matchLabels:
      app: nginx
      version: stable
  template:
    metadata:
      labels:
        app: nginx
        version: stable
    spec:
      containers:
        - name: nginx
          image: nginx:1.20

---
# 金丝雀版本
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
      version: canary
  template:
    metadata:
      labels:
        app: nginx
        version: canary
    spec:
      containers:
        - name: nginx
          image: nginx:1.21
```
