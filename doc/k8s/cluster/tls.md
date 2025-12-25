# 管理集群中的 TLS

二进制部署集群时，`TLS` 证书配置是最容易出问题的
每一个集群都有一个集群根证书颁发机构 `CA`，它是整个集群安全通信的基础，集群中的各个组件都需要依赖它

### Pod

##### 自动挂载 CA 证书

`k8s` 会自动将 `CA` 证书包挂载到每个 `Pod` 中

- 挂载地址
    - `/var/run/secrets/kubernetes.io/serviceacount/ca.crt`
- 适用范围
    - 使用默认 `Service Account`
- 证书定时自动轮换

##### 自定义 ServiceAccount

- 创建包含 `CA` 证书的 `ConfigMap`
- 将 `ConfigMap` 挂载到 `Pod` 中
- 程序中指定正确证书地址

### 创建管理证书签名

```bash
# 安装 cfssl
curl -L https://github.com/cloudflare/cfssl/releases/download/v1.6.4/cfssl_1.6.4_linux_amd64 -o cfssl
curl -L https://github.com/cloudflare/cfssl/releases/download/v1.6.4/cfssljson_1.6.4_linux_amd64 -o cfssljson
chmod +x cfssl cfssljson
sudo mv cfssl cfssljson /usr/local/bin/

cat <<EOF | cfssl genkey - | cfssljson -bare server
{
  "hosts": [
  "my-svc.my-namespace.svc.cluster.local",
  "my-pod.my-namespace.pod.cluster.local",
  "172.168.0.24",
  "10.0.34.2"
  ],
  "CN": "my-pod.my-namespace.pod.cluster.local",
  "key": {
  "algo": "ecdsa",
  "size": 256
  },
  "names": [
  {
    "C": "CN",
    "ST": "Beijing",
    "L": "Beijing",
    "O": "example",
    "OU": "example"
  }
  ]
}
EOF

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: my-svc.my-namespace
spec:
  request: $(cat server.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kubelet-serving
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF
```

### 证书批准和使用

##### 手动批准

具有适当权限的管理员可以手动批准或拒绝 `CSR`

```bash
# 批准证书
kubectl certificate approve my-svc.my-namespace

# 拒绝证书
kubectl certificate deny my-svc.my-namespace
```

##### 自动化证书管理

- 内置批准器
    - `csrapproving controller`
    - 主要用于 `kubelet` 客户端证书
- 自定义批准器

# kubelet 认证授权

`kubelet` 作为关键组件，其 `HTTPS` 端点暴露访问敏感数据 `API`，允许在节点和容器内执行各种权限级别的操作
为了保证集群安全，必须进行认证和授权

### 认证配置

##### 匿名访问控制

默认情况下，将所有未通过其他身份验证的方法视为匿名请求，并授予 `system:anonymous` 用户名和 `system:unauthenticated` 组

```bash
# 禁止匿名访问，返回 401 unauthenticated
kubelet --anonymous-auth=false
```

##### X.509 客户端证书认证

通过 `X.509` 客户端证书可实现强身份认证

```bash
kubelet --client-ca-file=/path/to/ca-bundle.crt

kube-apiserver --kubelet-client-certificate=/path/to/client.crt \
               --kubelet-client-key=/path/to/client.key
```

##### Bearer Token 认证

需要确保 `API Server` 中启用了 `authentication.k8s.io/v1`
`kubelet` 通过调用 `TokenReview API` 来验证用户信息

```bash
kubelet --authentication-token-webhook \
        --kubeconfig=/path/to/kubeconfig \
        --require-kubeconfig
```

### 授权配置

##### 默认授权模式

默认使用 `AlwaysAllow` 授权模式，运行所有经过身份验证的请求

##### Webhook

为了实现细微的访问控制，将授权委托给 `API Server`
确保启用 `authorization.k8s.io/v1`，之后会通过 `SubjectAccessReview` 确认请求授权

```bash
kubelet --authorization-mode=Webhook \
        --kubeconfig=/path/to/kubeconfig \
        --require-kubeconfig
```

### 请求属性映射

##### HTTP

- `POST`
    - `create`
- `GET`，`HEAD`
    - `get`
- `PUT`
    - `update`
- `PATCH`
    - `patch`
- `DELETE`
    - `delete`