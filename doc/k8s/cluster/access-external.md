# 从外部访问 `k8s` 中的 `Pod`

### hostNetwork 模式

当在 `Pod` 规格中设置 `hostNetwork: true` 时，`Pod` 将直接使用宿主机网络命名空间
意味着 `Pod` 中的应用程序可以直接绑定到当前宿主机的网络接口上

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: redis-demo
spec:
  hostNetwork: true
  containers:
    - name: redis-demo
      image: redis
      ports:
        - containerPort: 6379
```

##### 使用场景

- 网络插件 `DaemonSet` 部署
- 需要访问宿主机网络资源的系统级应用
- 对网络性能要求极高

### hostPort 端口映射

将容器端口直接映射到宿主机端口

```yaml
spec:
  containers:
    - name: redis-demo
      image: redis
      ports:
        - containerPort: 6379
          hostPort: 6379
          protocol: TCP
```

##### 适用场景

- `Nginx Ingress Controller` 等入口控制器
- 固定端口应用

### NodePort

在每个节点开放一个端口，将外部流量转发到对应 `Pod`

```yaml
spec:
  containers:
    - name: redis-demo
      image: redis
      ports:
        - containerPort: 6379
---
spec:
  type: NodePort
  ports:
    - port: 6379
      targetPort: 6379
      nodePort: 30086  # 可选，不指定则自动分配
  selector:
    app: redis-demo
```

### LoadBalancer 负载均衡器

自动创建云平台提供负载均衡器，并为 `Service` 分配一个外部 `IP`

```yaml
spec:
  type: LoadBalancer
  ports:
    - port: 6379
      targetPort: 6379
  selector:
    app: redis-demo
```

##### 适用场景

- 云平台环境
    - `AWS`
    - `GCP`
- 生产环境关键服务
- 需要高可用和自动故障转移

### Ingress 入口控制器

使用前需要部署对应 `Ingress Controller`

- `Nginx Ingress Controller`
- `Traefix`
- `HAProxy Ingress`
- `Istio Gateway`

##### 好处

- 统一入口
    - 单一负载均衡器处理多个服务
- 灵活路由
    - 支持基于域名、路径的路由规则
- `SSL` 终结
- 直接转发 `Pod`

##### 案例

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

```yaml
# 基础 Ingress 配置
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: redis-demo
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - host: redis.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service: # Service 必须存在，端口必须匹配
                name: redis-demo
                port:
                  number: 6379
```

##### 使用

- `Web` 应用
    - `Ingress + TLS`
- `API` 服务
    - 使用 `Ingress` 进行路由和负载均衡
- 数据库等有状态服务
    - `LoadBalancer` 或 `NodePort`
