# 用户与身份认证授权

- 服务账户
    - 主要用于集群内部组件和 `Pod` 访问
- 普通用户
    - 由外部独立服务管理

### 普通用户

普通用户通常由外部系统管理

- `k8s` 不存储普通用户对象
- 无法通过 `API` 创建普通用户

### 服务账户

- `k8s API` 管理
- 绑定到特定的 `namespace`
- 自动或者手动创建
- 可以关联到 `Secret`
- `Pod` 可挂载凭证和 `API` 通信

### 请求身份绑定

每个 `API` 请求必须绑定一个身份

- 普通用户
- 服务账号
- 匿名请求

### 认证

支持多种认证插件

##### 属性

认证插件会为请求关联属性

- 用户名
- `UID`
- 组
- 其他字段

##### 多重认证

可以启用多种认证方式，多模块验证，第一种成功可以短路后续验证
`system:authenticated` 包含所有已验证的用户

### 主要验证方式

##### X509 客户端证书

通过配置 `--client-ca-file` 启用

- 文件需包含一个或多个 CA
- 证书 subject 的 CN 作为用户名
- organization 字段为用户组，可多组

##### 静态 Token 文件

通过 `--token-auth-file` 启用：

- 文件格式
    - `token,user,uid,"group1,group2,group3"`
- Token 无限期有效，修改需重启 API server

##### Bootstrap Token

Bootstrap Token 用于集群初始化，格式为 `[a-z0-9]{6}.[a-z0-9]{16}`

```bash
--enable-bootstrap-token-auth
# Controller Manager
--controllers=*,tokencleaner
```

- 用户名
    - `system:bootstrap:<Token ID>`
- 组
    - `system:bootstrappers`

##### 静态密码

通过 `--basic-auth-file` 启用：

- 文件格式
    - `password,user,uid,"group1,group2,group3"`

##### Service Account Token

认证自动启动，使用签名 `bearer token`

- `--service-account-key-file`
    - 签名 `token` 的 `PEM` 文件
- `--service-account-lookup`
    - 启用后，`API` 删除的 `token` 会被撤销

- 用户名
    - `system:serviceaccount:(NAMESPACE):(SERVICEACCOUNT)`
- 组
    - `system:serviceaccounts`、`system:serviceaccounts:(NAMESPACE)`

##### OpenID Connect Token

- 登录身份提供商
- 获取 `access_token`、`id_token`、`refresh_token`
- 使用 `id_token` 作为 `bearer token`
- `API server` 验证 `JWT`
- 完成授权

`API Server` 配置参数

```bash
kubectl config set-credentials mmosley \
    --auth-provider=oidc \
    --auth-provider-arg=idp-issuer-url=https://oidcidp.example.com \ # 身份提供商 URL
    --auth-provider-arg=client-id=kubernetes \ # 客户端 ID
    --auth-provider-arg=client-secret=1db158f6-177d-4d9c-8a8b-d36869918ec5 \
    --auth-provider-arg=refresh-token=q1bKLFOyUiosTfawzA93TzZ... \
    --auth-provider-arg=id-token=eyJraWQiOiJDTj1vaWRjaWRwLnRyZW1vbG8...
```

##### Webhook Token

允许远程服务器验证

```yaml
clusters:
  - name: name-of-remote-authn-service
    cluster:
      certificate-authority: /path/to/ca.pem
      server: https://authn.example.com/authenticate

users:
  - name: name-of-api-server
    user:
      client-certificate: /path/to/cert.pem
      client-key: /path/to/key.pem

current-context: webhook
contexts:
  - context:
      cluster: name-of-remote-authn-service
      user: name-of-api-server
    name: webhook
```

##### 认证代理

通过请求 `header` 识别身份，管理员可以通过 `header` 模拟其他用户，便于策略调试

```bash
--requestheader-username-headers=X-Remote-User # 用户名
--requestheader-group-headers=X-Remote-Group # 用户组
--requestheader-extra-headers-prefix=X-Remote-Extra- # 额外字段
```
