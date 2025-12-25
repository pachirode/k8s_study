# Ip 伪装代理

通过配置 `iptables` 规则实现网络地址转换 `NAT`，将 `Pod` 的 `IP` 地址隐藏在集群节点的 `IP` 地址后面

### 相关概念

##### NAT

网络地址转换是一种通过修改 `IP` 数据包头中的源或目标地址，将一个 `IP` 地址重新映射到另一个 `IP`

##### Masquerading

地址伪装，一种特殊的 `NAT`，将多个源 `IP` 地址隐藏在单个地址后面，其中的单个地址通常为节点的 `IP`

##### CIDR

无类域间路由是一种基于可变长读子网掩码的 `IP` 地址分配方法，允许任意长度的网络前缀 `172.16.0.0/12`

### 工作原理

- 流量检测
    - 监控从 `Pod` 发出的网络流量
- 目标判断
    - 判断流量目标是否为集群内部地址
- 规则应用
    - 对访问外部地址的流量使用伪装规则
- 地址转换
    - 将 `Pod IP` 转为 `Node IP`

默认情况，集群内部地址不会进行伪装

- `10.0.0.0/8`
- `172.16.0.0/12`
- `192.168.0.0/16`
- `169.254.0.0/16`（本地链路）

### 部署伪装代理

##### 使用默认配置

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/ip-masq-agent/ip-masq-agent.yaml
```

##### 自定义配置部署

将配置文件声明为 `ConfigMap`

```yaml
nonMasqueradeCIDRs: # 不进行伪装 IP 的范围
  - 10.0.0.0/8
  - 192.168.0.0/16
resyncInterval: 60s # 配置文件自动重载时间
masqLinkLocal: false # 是否对本地链路地址进行伪装
```

### 使用环境

- 云环境
    - 虚拟机的出站流量必须使用虚拟机的 `IP` 地址
- 企业网络
    - 在企业网络，防火墙策略通常只允许来自特定的 `IP` 流量，通过伪装简化网络配置
- 服务网格
    - 在复杂的服务网格，有助于统一流量出口，简化网络策略和路由规则管理

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
