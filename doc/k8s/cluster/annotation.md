# Annotation

类似 `Label` 可以存放更大量数据，但是该数据可以被外部使用
不支持选择器，定义相对规范，支持更加复杂的数据结构

### 常见场景

- 配置管理信息
    - 声明式配置管理字段
    - 区分不同配置来源
    - 自动伸缩和自动调整系统配置信息
- 版本和构建信息
- 运维信息
    - 日志、监控
    - 审计数据存储地址
- 工具和集成信息
- 部署和管理信息

### 注解示例

##### Service Mesh

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
      annotations:
        # 控制 sidecar 注入
        sidecar.istio.io/inject: "true"
        # 配置代理资源限制
        sidecar.istio.io/proxyCPU: "100m"
        sidecar.istio.io/proxyMemory: "128Mi"
        # 配置流量策略
        traffic.sidecar.istio.io/includeInboundPorts: "8080,8443"
    spec:
      containers:
        - name: web-app
          image: nginx:1.21
          ports:
            - containerPort: 8080
```

##### CI/CD 集成

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: build-pod
  annotations:
    # 构建信息
    build.ci/pipeline-id: "12345"
    build.ci/commit-sha: "a1b2c3d4e5f6"
    build.ci/branch: "feature/new-api"
    build.ci/build-timestamp: "2023-12-01T10:30:00Z"
    # 部署信息
    deployment.company.com/owner: "team-backend"
    deployment.company.com/contact: "backend-team@company.com"
    deployment.company.com/documentation: "https://wiki.company.com/backend-api"
spec:
  containers:
    - name: app
      image: myapp:v1.2.3
```

