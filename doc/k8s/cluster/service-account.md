# Service Account Token 认证

适用于自动化脚本，第三方工具和 `Dashboard` 等场景

### 创建集群管理员 Token

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
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
    namespace: kube-system
```

### 获取 Token

##### 配置中读取

```bash
kubectl -n kube-system get secret $(kubectl -n kube-system get sa admin-user -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d
```

##### 创建临时 Token

到期之后不会自动刷新

```bash
kubectl -n kube-system create token admin-user
```

##### 创建长期 Token

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: admin-user-secret
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: admin-user
type: kubernetes.io/service-account-token
```

### 为特定命名空间创建用户 Token

```bash
# 为指定命名空间的用户分配权限
NAMESPACE="your-namespace"
ROLEBINDING_NAME="namespace-admin"
kubectl create rolebinding $ROLEBINDING_NAME \
  --clusterrole=admin \
  --serviceaccount=$NAMESPACE:default \
  --namespace=$NAMESPACE
# 获取该命名空间 Token
kubectl -n $NAMESPACE get secret $(kubectl -n $NAMESPACE get sa default -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d
```
