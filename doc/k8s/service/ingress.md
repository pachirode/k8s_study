# Ingress

集群中实现 `HTTP/HTTPS` 流量智能路由和安全暴露的核心机制，合理的配置可以实现灵活的服务访问与流量管理

用于管理集群外部到集群内部服务的 `HTTP` 和 `HTTPS`
访问，充当智能路由器，根据定义的规则将外部流量路由到集群内部的不同服务上，但是建议使用 `Gateway API`

### 功能

- 外部访问 `URL`
    - 为集群内服务提供外部可访问 `URL`
- 负载均衡
    - 多个 `Pod` 实例之间分发流量
- `SSL/TLS` 终结
    - 处理 `HTTPS` 证书和加密
- 基于名称的虚拟主机
    - 根据主机名路由到不同服务
- 路径路由
    - 根据 `URL` 路径将请求路由到不同服务

### 部署组件

- 部署 `Ingress` 控制器
- 配置 `IngressClass`，指定使用的控制器
- 准备好后端 `Service` 和 `Pod`

### 配置

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-service
                port:
                  number: 80
```

### IngressClass

定义 `Ingress` 的实现类别，支持集群范围和命名空间范围的参数配置

```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true" # 设置成默认 IngressClass
spec:
  controller: k8s.io/ingress-nginx
```

### 使用场景

##### 单服务暴露

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: single-service
spec:
  ingressClassName: nginx
  defaultBackend:
    service:
      name: web-service
      port:
        number: 80
```

##### 基于主机名的虚拟机

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: virtual-host
spec:
  ingressClassName: nginx
  rules:
    - host: blog.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: blog-service
                port:
                  number: 80
    - host: shop.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: shop-service
                port:
                  number: 80
```
