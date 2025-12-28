# kubeconfig 文件配置跨集群认证

为了简化多集群，多用户环境下的认证管理，使用 `kubeconfig` 文件管理
该文件集中管理集群连接信息，用户认证凭据和上下文配置，使得用户可以在不同集群和身份之间切换

```yaml
apiVersion: v1
kind: Config
current-context: production-context
preferences:
  colors: true
clusters:
  - cluster:
      certificate-authority: /path/to/ca.crt
      server: https://k8s-api.example.com:6443
    name: production-cluster
  - cluster:
      certificate-authority-data: LS0tLS1CRUdJTi...
      server: https://staging.k8s.local:6443
    name: staging-cluster
  - cluster:
      insecure-skip-tls-verify: true
      server: https://dev.k8s.local:8443
    name: dev-cluster
contexts:
  - context:
      cluster: production-cluster
      namespace: default
      user: admin-user
    name: production-context
  - context:
      cluster: staging-cluster
      namespace: testing
      user: developer-user
    name: staging-context
  - context:
      cluster: dev-cluster
      namespace: development
      user: dev-user
    name: dev-context
users:
  - name: admin-user
    user:
      client-certificate: /path/to/admin.crt
      client-key: /path/to/admin.key
  - name: developer-user
    user:
      token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjlrOXAy...
  - name: dev-user
    user:
      username: developer
      password: dev-password
```

### 核心组件

##### Cluster 配置

```yaml
clusters:
  - cluster:
      # API 服务器地址
      server: https://k8s-api.example.com:6443 # k8s API 服务器完整 URL
      # CA 证书文件路径
      certificate-authority: /path/to/ca.crt # CA 证书文件路径
      # 或者使用 base64 编码的证书数据
      certificate-authority-data: LS0tLS1CRUdJTi... # base64 编码 CA 证书数据
    name: production-cluster
  - cluster:
      server: https://dev.k8s.local:8443
      # 跳过 TLS 验证（仅用于开发环境）
      insecure-skip-tls-verify: true # 跳过 TLS 证书验证
    name: dev-cluster
```

```bash
# 管理集群配置
kubectl config set-cluster production \
  --server=https://k8s-api.example.com:6443 \
  --certificate-authority=/path/to/ca.crt
```

##### User 配置

```yaml
users:
  - name: cert-user
    user:
      client-certificate: /path/to/client.crt
      client-key: /path/to/client.key
  - name: token-user
    user:
      token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjlrOXAy...
  - name: basic-user
    user:
      username: developer
      password: secret-password
  - name: exec-user
    user:
      exec:
        apiVersion: client.authentication.k8s.io/v1beta1
        command: aws
        args:
          - eks
          - get-token
          - --cluster-name
          - my-cluster
```

```bash
# 设置证书认证
kubectl config set-credentials admin \
  --client-certificate=/path/to/admin.crt \
  --client-key=/path/to/admin.key

# 设置 token 认证
kubectl config set-credentials developer --token=your-token-here
```

##### Context 配置

将集群，用户组和命名空间组合起来

```yaml
contexts:
  - context:
      cluster: production-cluster
      user: admin-user
      namespace: kube-system
    name: prod-admin
  - context:
      cluster: staging-cluster
      user: developer-user
      namespace: development
    name: staging-dev
```

##### Current Context

使用 `current-context` 指定默认使用的上下文

```bash
# 切换当前上下文
kubectl config use-context staging-dev
```

### 配置文件加载机制

优先级

- 命令行参数
    - `--kubeconfig` 指定文件
- 环境变量
    - `$KUBECONFIG` 环境变量指定文件列表
- 默认位置
    - `~/.kube/config`

##### 合并规则

当使用多个 `kubeconfig` 文件

- 第一个设置特定值的文件优先
- 集群，用户，上下文信息不会覆盖，只会补充
- `current-context` 使用第一个文件中的设置
