# ServiceAccount

集群中 `Pod` 身份认证和权限控制的基础机制
为 `Pod` 内进程提供身份凭证，主要用于 `Pod` 和 `API Server` 的通信
每个 `namespace` 默认存在一个 `default` 账户

### 访问 API

`Pod` 内应用可以通过自动挂载 `ServiceAccount Token` 访问 `k8s API`
可以静止自动挂载凭证，`Pod` 中设置的优先级高于 `ServiceAccount`

### Token

`ServiceAccount` 默认不再自动创建 `Secret` 类型的长期 `Token`，使用 `BoundServiceAccountTokenVolume` 进行自动轮换

##### 手动创建长期 `Token`

手动长期 `Token` 存在安全风险，应当优先使用 `TokenRequest API` 或者短期 `Token`
通过手动创建 `Secret` 可以创建长期有效的 `Token`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: build-robot-secret
  annotations:
    kubernetes.io/service-account.name: build-robot
type: kubernetes.io/service-account-token
```

### 创建和管理

`ServiceAccount` 必须在 `Pod` 创建前存在
已创建的 `Pod` 不可更改其 `ServiceAccount`

###### 配置镜像拉取

创建包含镜像仓库凭证的 `Secret`

```bash
kubectl create secret docker-registry myregistrykey \
  --docker-server=<your-registry-server> \
  --docker-username=<your-name> \
  --docker-password=<your-password> \
  --docker-email=<your-email>
```

将 `Secret` 和 `ServiceAccount` 关联

```bash
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "myregistrykey"}]}'
```

成功配置之后，该 `namespace` 新建的 `Pod` 会自动包含镜像拉取的密钥

### RBAC 权限管理

通过 `RBAC` 可以为 `ServiceAccount` 赋予精细化的权限

```bash
# 创建 ServiceAccount
kubectl create serviceacount sample-sa

# 创建 ServiceAccount Token，此处为短期 Token，长期需要手动创建
kubectl create token sample-sa
```

##### 创建 ClusterRole

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: viewer-role
rules:
  - apiGroups: [ "" ]
    resources:
      - pods
      - pods/status
      - pods/log
      - services
      - services/status
      - endpoints
      - endpoints/status
    verbs:
      - get
      - list
      - watch
  - apiGroups: [ "apps" ]
    resources:
      - deployments
      - deployments/status
    verbs:
      - get
      - list
      - watch
```

##### 创建 ClusterRoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: sample-role-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: viewer-role
subjects:
  - kind: ServiceAccount
    name: sample-sa
    namespace: default
```

##### 配置 kubeconfig

```yaml
apiVersion: v1
clusters:
  - cluster:
      certificate-authority-data: <BASE64_ENCODED_CA_CERT>
      server: https://your-k8s-api-server:6443
    name: my-cluster
contexts:
  - context:
      cluster: my-cluster
      user: sample-user
    name: sample-context
current-context: sample-context
kind: Config
preferences: { }
users:
  - name: sample-user
    user:
      token: <SERVICE_ACCOUNT_TOKEN>
```
