# Ingress

网络流量管理的关键组件，决定外部请求如何安全，高效地路由到集群内部服务，实现弹性和可扩展网络架构的基础
在 `k8s` 集群中如果希望资源能够正常工作，必须部署至少一个 `Ingress` 控制器
`Ingress` 控制器需要用户根据实际需求单独部署和管理

### 官方支持的控制器

- `AWS Load Balancer Controller`
- `GCE Ingress Controller`
- `NGINX Ingress Controller`

### 多控制器管理

有时候需要运行多个 `Ingress` 控制器来满足需求

##### IngressClass 资源

可以在同一个集群中部署和管理多个 `Ingress` 控制器

```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
spec:
  controller: k8s.io/ingress-nginx
```

##### 指定控制器类型

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
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
                name: example-service
                port:
                  number: 80
```

##### 默认控制器设置

如果没有在 `Ingress` 资源中指定 `IngressClassName`，会自动应用默认的 `IngressClass`
可以通过 `IngressClass` 资源添加如下注解来设置默认控制器

```yaml
metadata:
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"
```

