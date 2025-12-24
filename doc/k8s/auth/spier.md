# SPIRE

`SPIFFE` 的生产就绪实现，执行节点和工作负载认证，根据预定义条件安全的向工作负载发布 `SVID` 和验证 `SVID`

### 架构

- `SPIRE` 服务器
    - 作为证书颁发机构 `CA`，通过代理向工作负载分发身份，并维护身份注册表
- 一个或者多个 `SPIRE` 代理
    - 部署在每个运行工作负载节点上

### SPIRE 服务器

管理和发布信任域内的所有身份

- 存储注册条目
    - 决定 `SPIFFE ID` 签发的选择器
- 管理签名密钥
- 自动验证代理身份
- 为以验证的代理请求的工作负载创建 `SVID`

##### 插件

通过插件机制实现高度可扩展性

- 节点证明器
    - 与代理协作，验证代理节点身份
- 节点解析器
    - 扩展节点选择器，增强节点识别能力
- 数据存储
    - 存储注册条目，节点和选择器
- 密钥管理
- 上游 `CA` 集成

### SPIRE 代理

需要运行在每个节点上

- 从服务器请求并缓存 `SVID`
- 向本地工作负载暴露 `SPIFFE API`
- 证明调用 `API` 工作负载身份
- 为已识别工作负载分发 `SVID`

##### 核心组件

- 节点证明器插件
    - 节点身份证明
- 工作负载证明器
    - 本地工作负载身份证明
- 密钥管理器
    - 生成和管理工作负载私钥

### 自定义插件

`SPIRE` 支持自定义插件开发，适配不同平台和安全需求
插件可以动态加载，无需重新编译

- 定制节点，代理节点验证器
- 自定义密钥管理器插件
- 平台专用工作负载证明器

### 身份证明

##### 节点证明

代理首次连接服务器需要完成节点证明

- 云平台实例身份文档
    - `AWS EC2`
    - `Azure`
- 硬件安全模块
    - `HSM`
    - `TPM`
- 预共享加入令牌
- `k8s` 服务账户令牌
- 当前的 `X509`

##### 工作负载证明

代理通过本地权限，识别调用 `API` 进程属性

- 操作系统调度信息
    - `uid`
    - `gid`
- 容器编排信息
    - `k8s` 服务账户，命名空间等

### SVID 身份颁发

- `SPIRE` 服务器启动，生成自签名证书
- 服务器初始化信任包并开放注册 `API`
- 节点上的 `SPIRE` 代理启动，执行节点证明
- 代理通过 `TLS` 向服务器提交证明材料
- 服务器调用云平台 `API` 验证
- 服务器完成节点解析，更新注册条目
- 服务器向代理节点发放 `SVID`
- 代理用节点 `SVID` 认证服务器，获取授权注册条目
- 代理为工作负载生成 `CSR`，服务器签发 工作负载 `SVID`
- 代理缓存 `SVID` 并监听工作负载 `API`

##### 授权注册条目

服务器仅向代理下发授权条目

- 查询以 `SPIFFE ID` 为父 `ID` 的注册条目
- 查询节点选择器匹配的注册条目

### SPIRE 工作负载注册器

工作负载器支持多种自动注册模式

##### 服务账户模式

基于 `k8s` 服务账户自动生成 `SPIFFE ID`

```text
spiffe://<TRUST_DOMAIN>/ns/<NAMESPACE>/sa/<SERVICE_ACCOUNT>
```

注册条目

```text
Entry ID      : 200d8b19-8334-443d-9494-f65d0ad64eb5
SPIFFE ID     : spiffe://example.org/ns/production/sa/blog
Parent ID     : spiffe://example.org/spire/agent/k8s_psat/production/node-123
Selectors     : k8s:ns:production
        k8s:pod-name:blog-app-98b6b79fd-jnv5m
```

##### Pod 标签模式

基于指定 `Pod` 标签生成 `SPIFFE ID`
`spire-workload` 标签

##### Pod 注解模式

基于指定 `Pod` 注解值生成自定义 `SPIFFE ID`
`spiffe.io/spiffe-id` 注解

##### 联合身份注册

通过 `spiffe.io/federatesWith` 注解实现跨信任域

```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    spiffe.io/federatesWith: "partner-domain.com,vendor-domain.org"
```

### 部署

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: spire-server
spec:
  template:
    spec:
      containers:
        - name: spire-server
          # SPIRE 服务器配置
        - name: k8s-workload-registrar
          image: ghcr.io/spiffe/k8s-workload-registrar:1.8.0
          args:
            - -config
            - /opt/spire/conf/k8s-workload-registrar.conf
          volumeMounts:
            - name: spire-server-socket
              mountPath: /tmp/spire-server/private
            - name: registrar-config
              mountPath: /opt/spire/conf
      volumes:
        - name: spire-server-socket
          emptyDir: { }
        - name: registrar-config
          configMap:
            name: k8s-workload-registrar
```

##### 运行模式

- `Webhook` 模式
    - 基于 `ValidatingAdmissionWebhook`
    - 适用于小规模环境
- `Reconcile`
    - 基于控制器协调机制
    - 生成环境首选
- `CRD`
    - 基于自定义资源

### DNS 支持

在 `Reconcile` 和 `CRD` 模式下，可以为 `Pod` 注册条目添加 `DNS` 名称
部分服务对 `DNS` 反向解析有要求（`etcd`），可以直接禁止这个功能
