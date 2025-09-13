# `Staging`

暂存区，用来保存未来会发布到其他仓库的代码，里面的项目会定期同步到 `k8s.io` 组织的其他仓库中

- `api`
    - 所有 `K8S` 内置的资源 `API` 定义
- `client-go`
- `code-generator`
    - 代码生成器，可以根据 `K8S API` 定义生成客户端代码，深度拷贝函数等
- `cri-api`
    - 容器运行时接口，`kubelet` 可以通过这个接口和各种容器运行时交互
- `kms`
    - 提供对 `K8S` 密钥管理服务的支持，使得 `K8S` 可以和外部密钥管理系统进行集成
- `kubelet`
    - `K8S` 节点代理，在每个节点上运行，负责管理 `Pod` 的生命周期
- `metrics`
    - 提供 `K8S` 监控指标的定义
        - 节点资源利用率，`Pod` 指标
- `sample-cli-plugin`
    - `K8S` 插件示例项目，演示如何开发和部署自定义的 `kubectl` 命令行工具
- `apiextensions-apiserver`
    - 允许用户自定义 `K8S` 资源对象
        - `CRD` 相关实现
- `cli-runtime`
    - 提供 `K8S CLI` 工具的基础库
        - 命令解析
        - 配置管理
- `component-base`
    - 包含 `K8S` 组件的基础功能
        - 日志记录
        - 指标收集
        - 健康检查
- `csi-translation-lib`
    - 提供容器存储接口 `CSI` 到 `K8S` 存储接口的转换功能
- `kube-aggregator`
    - 允许第三方 `API` 注册到 `K8S API` 服务器，扩展 `API` 功能
- `kube-proxy`
    - 网络代理
        - `Service` 负载均衡
        - `IP` 虚拟化
- `mount-utils`
    - 文件挂载相关的工具函数
- `sample-controller`
    - 自定义控制器示例
- `apimachinery`
    - `K8S API` 核心库
        - 资源对象的 `API` 结构和解码规则
- `cloud-provider`
    - 和云服务提供商集成的接口定义
- `component-helpers`
    - 提供了一些公共组件和功能
        - 工具函数
        - 配置管理
- `dynamic-resource-allocation`
    - 提供动态资源分配的功能
        - 节点上 `CPU` 资源的分配
- `kube-controller-manager`
    - 核心组件，负责运行各种控制器
- `kube-scheduler`
    - 负责 `Pod` 的调度
- `pod-security-admission`
    - 提供 `Pod` 安全策略的实现，用于限制 `Pod` 的安全相关的配置
- `apiserver`
    - 核心组件，提供整个 `API` 服务
- `cluster-bootstrap`
    - 提供 `K8S` 集群初始化和引导功能，负责集群的基础设施
        - 证书
        - 配置文件
- `controller-manager`
    - 控制器的的核心功能
- `endpointslice`
    - 提供 `EndpointSlice` 资源分片的实现，可以更好的扩展和管理大规模 `Endpoints`
- `kubectl`
    - 命令行工具，用于集群进行交互
- `legacy-cloud-providers`
    - 旧版云提供山支持
- `sample-apiserver`
    - 自定义控制器示例

# `Cmd`

### 控制面组件

- `kube-apiserver`
- `kube-controller-manager`
- `cloud-controller-manager`
- `kube-scheduler`
- `kubelet`
- `kube-proxy`

### 客户端工具

- `kubeadm`
- `kubectl`

### 辅助工具

- `clicheck`
- `genkubedocs`
- `gendocs`
- `genman`
- `genswaggertypedocs`
- `genyaml`
- `kubectl-convert`
- `kubemark`

### 其他

- `dependencycheck`
- `dependencyverifier`
- `genutils`
- `fieldnamedocscheck`
- `prune-junit-xml`
- `importverifier`
- `preferredimports`
- `import-boss`
- `gotemplate`

### `API`

- `k8s.io/api`
    - 包含内置资源对象的结构体定义，以及这些资源对象的操作和状态
    - 操作
        - 主要包括针对每种资源对象 `Marshal` `Unmarshal` 等
    - 状态
        - 涉及到资源的状态
            - `XXXConditionType`
- `kubernetes/pkg/api`
    - 核心资源对象 `util` 类型函数
- `kubernetes/pkg/apis`
    - 和 `k8s.io/api` 包内容相似，包含内置资源对象的结构体定义

### 代码结构设计

- `Options`
- `NewOptions`
- `opts.Complete`
- `opts.Validate`
- `NewConfig`
- `config.Complete`

# 架构

### 原始阶段

### 精简 `main` 文件

将命令行参数设置，命令行程序构建，程序初始化等代码剥离出 `main` 文件，保证文件的简单性

- `pkg/util`
- `pkg/version/verflag`
- `pkg/master/server`

### 应用代码分离

`cmd` 目录下新增 `app` 目录，将之前 `pkg/master/server` 实现的应用初始化，启动等核心代码迁移

应用分层

- `cmd/kube-apiserver`
- `cmd/kube-apiserver/app`
    - 应用层，负责应用命令行参数是的设置，应用初始化和启动等
- `pkg/master`
    - 业务层

### 命令行参数剥离

剥离命令行参数到 `cmd/xxx/app/options`，代码按照不同的功能存放到不同文件中 `validation.go` 存放验证相关方法
引入动态配置功能

- `XXXOptions struct`
    - 命令行选项的从操作对象
- `NewXXXOptions`
    - 创建一个带默认值的 `XXXOptions` 实例
- `AddFlags`
    - 在该方法中设置命令行参数，并将命令行参数的值绑定到结构体字段值中

动态配置
`K8S` 的各个组件在 `v1.2.0` 之前都是通过命令行参数进行配置的
这种方式在命令行参数不多的情况下问题不大，一旦参数过多就会变的难以阅读

- 命令行参数过多，启动命令太长
- 命令行参数过多，管理成本会大于配置文件

`kubelet` 组件是部署在每一个 `Node` 节点上的，更新配置的时候往往需要管理员先通过 `SSH`
登录到节点，修改配置再重新启动 `kubelet` 组件，需要很高的维护成本
因此使用配置中心的机制，通过配置中心，触发配置文件的变更和 `kubelet` 组件的重启

- 引入第三方配置中心组件
    - `Apollo`
    - `Etcd`
- 复用 `K8S` 机制
    - 增加一个配置类型的 `API` 资源，并 `Watch kube-apiserver`

```yaml
apiVersion: kubelet.config.k8s.io/v1alpha1
kind: KubeletConfiguration
```

配置项会保存在 `ConfigMap` 资源的 `data` 字段中，`kubelet` 会 `watch ConfigMap`，当 `ConfigMap` 有变化时，`kubelet`
会将 `ConfigMap data` 中的字段中的配置项写到本地磁盘，然后退出进程，操作系统级别的进程管理服务自动重新拉起 `kubelet`

### 应用构建框架化

使用 `cobra` 框架来构建并启动应用

# 应用构建模型

应用三大基本功能，将其拆分出来，可以提高服务的稳定性和可维护性

- 应用框架构建
    - 命令行程序
    - 命令行参数解析
        - `cmd/kube-xxx/app/options`
            - `cmd/kube-xxx/app/options/options.go`
            - `cmd/kube-xxx/app/options/completion.go`
    - 配置文件解析
- 应用初始化
    - 服务初始化
        - 应用框架的初始化命令
        - 命令行参数的设置
    - 业务初始化
        - 业务相关代码初始化
            - 数据库创建
            - `API` 路由初始化
            - 认证授权初始化
- 服务启动