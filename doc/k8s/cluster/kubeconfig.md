# kubeconfig 用户授权

其他人员想要使用 `kubectl`，需要对用户身份进行认证并对其权限做出限制

### 创建用户证书

##### 准备证书文件

```json
{
  "CN": "devuser",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
```

##### 生成用户证书和私钥

需要确保设计到的文件都存在

```bash
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes devuser-csr.json | cfssljson -bare devuser
```

### 配置 kubeconfig 文件

配置文件理解可以类比 `git`

##### 创建用户 kubeconfig

```bash
# 设置集群参数
export KUBE_APISERVER="https://172.20.0.113:6443"
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=devuser.kubeconfig

# 设置客户端认证参数
kubectl config set-credentials devuser \
  --client-certificate=/etc/kubernetes/ssl/devuser.pem \
  --client-key=/etc/kubernetes/ssl/devuser-key.pem \
  --embed-certs=true \
  --kubeconfig=devuser.kubeconfig

# 设置上下文参数
kubectl config set-context kubernetes \
  --cluster=kubernetes \
  --user=devuser \
  --namespace=dev \
  --kubeconfig=devuser.kubeconfig

# 设置默认上下文
kubectl config use-context kubernetes --kubeconfig=devuser.kubeconfig
```

##### 使用 kubeconfig

```bash
# 备份原有配置（可选）
cp ~/.kube/config ~/.kube/config.backup

# 应用新配置
cp ./devuser.kubeconfig ~/.kube/config
```

### 配置 RBAC 权限

##### 创建角色绑定

为了限制 `devuser` 用户的权限范围，使用 RBAC 将用户绑定到特定的 namespace：

```bash
# 为 dev namespace 创建角色绑定
kubectl create rolebinding devuser-admin-binding \
  --clusterrole=admin \
  --user=devuser \
  --namespace=dev

# 为 test namespace 创建角色绑定
kubectl create rolebinding devuser-admin-binding-test \
  --clusterrole=admin \
  --user=devuser \
  --namespace=test
```

### 配置检查

验证 `kubectl` 是否使用了正确的用户身份

```bash
kubectl config get-contexts
```

### Dashboard 认证

登录需要进行特殊处理，需要在生成的 `.kubeconfig` 文件中手动添加 `token` 字段
使用 `kubeconfig` 登录 `Dashboard` 必须包含 `token`

