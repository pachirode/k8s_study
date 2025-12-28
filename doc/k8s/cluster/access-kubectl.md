# kubectl 访问集群

### 配置

访问集群需要集群地址和访问凭证，这些信息通常是部署之后自动配置或集群管理员提供

```bash
# 查看配置
kubectl config view
# 验证连接
kubectl cluster-info
kubectl get nodes
```

### 直接访问

##### kubectl proxy

```bash
# 启动代理
kubectl proxy --port=8080
curl http://localhost:8080/api/v1
```

##### 使用认证访问

```bash
# 获取 API server 地址
APISERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

# 获取访问令牌
TOKEN=$(kubectl get secret $(kubectl get serviceaccount default -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 --decode)

# 访问 API
curl $APISERVER/api/v1 --header "Authorization: Bearer $TOKEN" --insecure
```

### Pod 中访问

##### 服务发现

查找 `API server`

- `DNS`
    - `kubernetes.default.svc.cluster.local`
- 环境变量
    - `KUBERNETES_SERVICE_HOST`
    - `KUBERNETES_SERVICE_PORT`

##### 服务凭证

- `Token`
    - `/var/run/secrets/kubernetes.io/serviceaccount/token`
- `CA`
    - `/var/run/secrets/kubernetes.io/serviceaccount/ca.crt`
- `namespace`
    - `/var/run/secrets/kubernetes.io/serviceaccount/namespace`

### 访问集群中服务

- `ClusterIP`
    - 集群内访问，用于内部通讯
- `NodePort`
    - 节点端口访问，开发测试环境
- `LoadBalancer`
    - 外部负载均衡器，生产环境对外服务
- `ExternalName`
    - `DNS`，访问对外服务

##### 代理访问

```bash
kubectl proxy
curl - L http://localhost:8080/api/v1/namespaces/{namespace}/services/{service-name}:{port}/proxy/
```

代理类型

- `kubectl proxy`
    - 运行在客户端
    - `HTTP` 到 `HTTPS` 转换
    - 自动处理认证
- `api server proxy`
    - 内置在 `api server`
    - 用于访问集群内资源
    - 支持负载均衡
- `kube-proxy`
    - 运行在每个节点
    - 处理服务流量转发
    - 支持多种代理模式
- `ingress controller`
    - 七层负载均衡
    - `HTTP/HTTPS` 路由
    - `SSL` 终结
- `cloud load balancer`
    - 云提供商
    - 外部流量入口
    - 高可用支持

##### 端口转发

```bash
# 转发到 Pod
kubectl port-forward pod/my-pod 8080:80

# 转发到服务
kubectl port-forward service/my-service 8080:80
```

##### 内置服务

访问内置服务需要有相应的 `RBAC` 权限

```bash
kubectl cluster-info
```

### 调试命令

```bash
# 检查集群状态
kubectl cluster-info dump

# 查看详细错误信息
kubectl get events --sort-by=.metadata.creationTimestamp

# 测试 API 连接
kubectl auth can-i '*' '*' --all-namespaces
```
