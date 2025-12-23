# GateWay API

替代 `Ingress` 的方案，支持跨命名空间路由绑定

### 设计

为不同场景定义了四类角色

- 基础设施提供
    - 提供 `GatewayClass` 实现
- 集群运维人员
    - 管理 `Gateway` 实例
- 应用开发者
    - 定义路由需求
- 应用管理员
    - 配置应用级策略

### 资源模型

##### GatewayClass

定义网关类，由基础设施提供方创建，支持参数化配置

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: cloud-gateway
spec:
  controllerName: "example.com/gateway-controller"
  description: "云服务提供商的网关实现"
```

##### GateWay

外部流量如何路由到集群服务，支持多监听器和灵活的 `TLS` 配置

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: production-gateway
  namespace: gateway-system
spec:
  gatewayClassName: cloud-gateway
  listeners:
    - name: http
      port: 80
      protocol: HTTP
      allowedRoutes:
        namespaces:
          from: Selector
          selector:
            matchLabels:
              environment: production
    - name: https
      port: 443
      protocol: HTTPS
      hostname: "*.example.com"
      tls:
        mode: Terminate
        certificateRefs:
          - kind: Secret
            name: wildcard-tls-cert
  addresses:
    - type: NamedAddress
      value: "production-lb"
```

### Route

##### HTTPRoute

用于分割 `HTTP/HTTPS` 流量的路由

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: api-route
  namespace: production
spec:
  parentRefs:
    - name: production-gateway
      namespace: gateway-system
  hostnames:
    - api.example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /v1/
        - headers:
            - name: X-API-Version
              value: v1
      filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
              - name: X-Forwarded-Host
                value: api.example.com
      backendRefs:
        - name: api-v1-service
          port: 8080
          weight: 90
        - name: api-v1-canary-service
          port: 8080
          weight: 10
    - matches:
        - path:
            type: PathPrefix
            value: /v2/
      backendRefs:
        - name: api-v2-service
          port: 8080
```

##### GRPCRoute

##### TLSRoute

### 跨命名空间引用

### 路由绑定和限制

# Ingress 迁移 GateWay

### 局限性

- 仅支持基本的 `HTTP/HTTPS` 流量，`TLS` 终止功能
- 路由规则支持有限
- 严重依赖注解

### 配置转换

迁移时需要将 `Ingress` 资源的各项功能映射到 `GateWay API`

##### 入口配置

`Ingress` 入口为隐藏的 （默认 `80/443`），`GateWay` 需要显示定义监听器

##### 注解扩展

`Ingress` 依赖注解，在 `Gateway API` 中可通过 `Policy` 资源等标准方式实现

##### 导出现有的 Ingress 配置

```bash
kubectl get ingress -o yaml > current-ingress.yaml
kubectl get ingress -o jsonpath='{.items[*].spec.rules[*].host}' | tr ' ' '\n' | sort -u
kubectl get ingress -o jsonpath='{.items[*].spec.tls[*].secretName}' | tr ' ' '\n' | sort -u
kubectl get ingress -o jsonpath='{.items[*].metadata.annotations}' | jq .
```

##### 创建 Gateway

- 创建 `GatewayClass`
- 定义 `Gateway` 资源
- 创建 `HTTPRoute` 资源

### Ingress2Gateway

自动迁移工具，支持注解保留，跨命名空间等选项

