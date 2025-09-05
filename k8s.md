# `Kubernetes`

`Kubernetes` 是一个开源的容器编排平台，管理容器化的工作负载和服务，可促进声明式配置和自动化

### 核心功能

- 服务器发现和负载均衡
    - 可以使用 `DNS` 名称或者自己的 `IP` 地址来暴露容器
    - 如果进入容器的流量很大，可以复杂均衡分配网络流量
- 存储编排
    - 允许自动挂载需要的存储系统
        - 本地存储
        - 公共云
- 自动部署和回滚
    - 描述已部署的容器需要的状态，以受控制的速率将实际状态更改为期望状态
- 自动完成装箱计算
    - `Kubernetes` 提供许多节点组成的集群，这个集群上运气容器化任务
    - 告诉`Kubernetes` 集群，如何运行容器（每个容器需要多少 `CPU` 和内存 `RAM`），按照实际情况自动调度节点
- 自我修复
    - 重新启动失败容器，替换容器，杀死不响应用户定义的运行状态检查的容器
- 密钥和配置管理
    - 存储和管理敏感信息，可以在不重建容器的情况下更新密钥和程序配置
- 批处理执行
- 水平扩容缩容
- `IPv4/IPv6` 双栈
- 可扩展

### 架构

采用 `Master-Worker` 的架构模式

##### `Master`

部署了 `Kubernetes` 控制面的核心组件
企业集群中一般会部署 `kube-apiserver`、`kube-controller-manager`、`kube-scheduler`
，其中 `kube-controller-mananger`、`kube-scheduler` 会通过本地回环地址和 `kube-apiserver` 进行通讯
`kube-controller-manager` 和 `kube-scheduler` 之间没有通信
这些核心的控制面组件用来完成 `Kubernetes` 资源的 `CURD`、并根据资源的定义执行相应的业务逻辑

为了保障控制面组件的稳定，`Master` 节点不会运行 `workload`

##### `Worker`

主要用来运行 `Pod`
部署了 `kubelet` 和 `kube-proxy` 组件
`kubelet` 负责和底层容器进行交互，用来管理容器的生命周期
`kube-proxy` 作为集群内的服务注册中心，负责服务发现和负载均衡

### 组件交互

##### `kube-apiserver`

非常核心的组件，承载着所有资源的增删改查，认证，鉴权等逻辑；为了确保高可用，可以将 `kube-apiserver`
实例注册到负载均衡器中，通过负载均衡器来访问（通常至少为三个）

`client-go` 其实就是 `Go` 语言实现的 `SDK`，封装了访问 `kube-apiserver API` 接口的方法
`kubectl` 是命令行工具，可以用来访问 `kube-apiserver`

实际上的访问顺序

1. `kubectl`
2. `client-go`
3. `RESTful API`
4. `kube-apiserver`
    - 请求到达之后会对请求进行身份认证和资源鉴权
    - 准入控制，设置默认值，校验和版本转换等逻辑，并最终将数据保存到 `Etcd` 中

`kube-apiserver` 是一个标准的 `REST` 服务器，内置了很多 `REST` 资源。也支持自定义资源，`CRD`，通过 `CRD` 可以极大的提高扩展能力
访问 `kube-apiserver` 本质上就是对内置资源和自定义资源进行增删改查等操作，并将数据保存或者更新到 `Etcd` 中

##### `kube-controller-manager`、`kube-scheduler`、`kubelet`、`kube-proxy`

`kube-controller-manager`、`kube-scheduler`、`kubelet`、`kube-proxy` 这些组件，通过 `List-Watch` 机制，感知 `kube-apiserver`
中资源的变化，当资源被执行着的增删改查操作之后，会产生对应的变更事件

###### `kube-controller-mananger`

内置了很多资源的 `controller`，这些 `controller watch` 到关注的资源发生变更之后，会进行状态调和，根据资源定义，确保资源状态始终维持在声明的状态中
维持状态的逻辑，保存在各个 `controller` 代码中

##### `kube-scheduler`

集群的调度器，用来调度 `Pod` 到具体的 `Node` 节点
一个 `Pod` 被创建出来需要调度到具体的节点上运行
`kube-scheduler` 会根据 `Pod` 的定义，节点状态等因素，根据调度策略将 `Pod` 调度到具体节点

##### `kubelet`

`kube-scheduler` 将 `Pod` 调度到具体节点之后，会产生一个 `Pod UPDATE` 事件
`kubelet watch Pod` 变更事件后，如果发现 `spec.nodeName` 值和 `kubelet` 所在的节点名相同，会根据 `Pod`
定义，调用底层的容器运行，在节点上创建需要的容器

##### `kube-proxy`

集群服务的发现组件和负载均衡器
`kube-proxy` 会 `Watch Service Pod`，并动态维护一个 `Service IP（VIP）` 和 `Pod IP（RS）` 列表的映射，在 `Service` 和 `Pod`
有更新时，会动态的更新这个映射表
如果通过 `Service IP` 访问时，`kube-proxy` 会根据负载均衡策略，选择一个 `Pod IP`，将请求转发到这个 `Pod` 中，起到负载均衡器的功能

### 组件功能

##### 控制面组件

集群的核心部分，负责管理和维护整个集群的状态，由多个组件组成，每个组件都有特定功能

###### `kube-apiserver`

操作资源对象的唯一入口，只有 `kube-apiserver` 会与 `etcd` 进行交互