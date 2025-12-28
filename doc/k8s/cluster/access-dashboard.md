# Dashboard

`k8s` 官方提供的通用 `Web UI`，由一组微服务组成
`7.0.0` 开始仅支持 `Helm` 的安装，采用了多容器架构并强依赖 `Kong` 网关代理

### 核心组件

- `Web UI`
    - 提供与集群交互的用户界面
- `API Module`
    - 处理 `REST` 和 `GraphQL API` 请求
- `Auth Module`
    - 管理认证和授权
- `Metrics Scraper`
    - 从 `metrics server` 收集性能指标
- `Kong Gateway`
    - 中央 `API` 代理，在组件之间路由流量

### 功能

- 多集群支持
    - 支持连接和管理多个集群
- 资源概览
    - 提供集群、节点、命名空间
- 工作负载管理
    - 支持查看和管理资源
- 存储管理
- `YAML/JSON` 编辑器
- 简单的应用部署向导
- 集成 `Pod` 日志查看
- 提供对 `Pod` 终端访问

### 安装

##### helm

```bash
# 添加 Kubernetes Dashboard 仓库
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo update

# 安装 Dashboard
helm install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  --create-namespace \
  --namespace kubernetes-dashboard

# 创建管理员 ServiceAccount
kubectl create serviceaccount dashboard-admin -n kubernetes-dashboard

# 创建 ClusterRoleBinding
kubectl create clusterrolebinding dashboard-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=kubernetes-dashboard:dashboard-admin

```

##### 手动

```bash
# 部署 Dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v3.0.0-alpha0/charts/kubernetes-dashboard.yaml

# 创建管理员用户
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
```

### 访问 Dashboard

##### 端口转发访问

```bash
# 创建端口转发
kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard-kong-proxy 8443:443

# 获取访问令牌
kubectl get secret -n kubernetes-dashboard \
  $(kubectl get serviceaccount dashboard-admin -n kubernetes-dashboard -o jsonpath="{.secrets[0].name}") \
  -o jsonpath="{.data.token}" | base64 --decode

# 访问 https://localhost:8443
```

##### Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  ingressClassName: nginx
  rules:
    - host: dashboard.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kubernetes-dashboard-kong-proxy
                port:
                  number: 443
```
