# TLS Bootstrap

`TLS` 客户端引导功能，提供一个从集群证书颁发机构自动请求证书 `API`，为 `TLS` 客户端提供证书自动化管理能力

### kube-apiserver 配置

启用 `TLS Bootstrap` 前，需为 `kube-apiserver` 配置 `Token` 认证和客户端证书 `CA`

##### Token

首先配置 `bootstrap token` 文件

```bash
# 生成随机 Token
head -c 16 /dev/urandom | od -An -t x | tr -d ' '
5c48e08ccfce393f432b88403c593614

# 创建 token 文件
# token;用户名;用户ID;组名
5c48e08ccfce393f432b88403c593614,kubelet-bootstrap,10001,"system:kubelet-bootstrap"

# kube-apiserver 启用 Token 认证
--token-auth-file=/path/to/token-file
```

##### 客户端配置

```bash
--client-ca-file=/var/lib/kubernetes/ca.pem
```

### kube-controller-manager

负责证书签发和 `CSR` 审批，需要配置正确的 `CA` 和相关控制器

##### 证书签名配置

```bash
--cluster-signing-cert-file="/etc/kubernetes/pki/ca.crt"
--cluster-signing-key-file="/etc/kubernetes/pki/ca.key"
```

##### CSR 审批控制器

内置 `csrapproving` 控制器默认启用

- `nodeclient`
    - 节点客户端认证请求
- `selfnodeclient`
    - 节点更新自身客户端证书
- `selfnodeserver`
    - 节点更新服务端证书
    - 需要启用 `feature gate`

```bash
# 启用服务端证书轮转
--feature-gates=RotateKubeletServerCertificate=true
```

##### RBAC 权限配置

为了保证 `CSR` 能够自动被审批，需要配置相应的 `ClusterRole` 和 `ClusterRoleBinding`

```yaml
# 审批节点客户端证书请求
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: approve-node-client-csr
rules:
  - apiGroups: [ "certificates.k8s.io" ]
    resources: [ "certificatesigningrequests/nodeclient" ]
    verbs: [ "create" ]
---
# 审批节点客户端证书续期
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: approve-node-client-renewal-csr
rules:
  - apiGroups: [ "certificates.k8s.io" ]
    resources: [ "certificatesigningrequests/selfnodeclient" ]
    verbs: [ "create" ]
---
# 审批节点服务端证书续期
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: approve-node-server-renewal-csr
rules:
  - apiGroups: [ "certificates.k8s.io" ]
    resources: [ "certificatesigningrequests/selfnodeserver" ]
    verbs: [ "create" ]
```

```yaml
# 为 kubelet-bootstrap 组自动审批 CSR
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: auto-approve-csrs-for-group
subjects:
  - kind: Group
    name: system:kubelet-bootstrap
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: approve-node-client-csr
  apiGroup: rbac.authorization.k8s.io
---
# 为节点续期授予权限
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: auto-approve-renewals-for-nodes
subjects:
  - kind: Group
    name: system:nodes
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: approve-node-client-renewal-csr
  apiGroup: rbac.authorization.k8s.io
```

### kubelet 配置

`kubelete` 作为节点代理，需要配置 `bootstrap kubeconfig` 及相关启动参数

###### 创建 bootstrap kubeconfig

```bash
# 设置集群信息
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/pki/ca.crt \
  --embed-certs=true \
  --server=https://k8s-api:6443 \
  --kubeconfig=bootstrap.kubeconfig

# 设置认证信息
kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=bootstrap.kubeconfig

# 设置上下文
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=bootstrap.kubeconfig

# 使用默认上下文
kubectl config use-context default --kubeconfig=bootstrap.kubeconfig
```

##### 启动参数

```bash
--bootstrap-kubeconfig="/path/to/bootstrap.kubeconfig"
--kubeconfig="/var/lib/kubelet/kubeconfig"
--cert-dir="/var/lib/kubelet/pki"
--rotate-certificates=true
--rotate-server-certificates=true
```
