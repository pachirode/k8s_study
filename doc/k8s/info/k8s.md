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

# 组件功能

##### 控制面组件

集群的核心部分，负责管理和维护整个集群的状态，由多个组件组成，每个组件都有特定功能

###### `kube-apiserver`

操作资源对象的唯一入口，只有 `kube-apiserver` 会与 `etcd` 进行交互，其他模块要和 `etcd` 通信需要经过 `kube-apiserver`

- `API` 服务
    - 提供 `Kubernetes API`接口，供其他用户和组件进行交互
- 资源管理
    - 负责管理集群资源
        - `Pods`
        - `Services`
        - `Deployments`
- 认证和授权
    - 用户身份认证
    - 用户授权
- 审计日志
    - 记录所有 `API` 请求和操作审计日志，可用于安全审计和问题排查
- `API` 版本管理
    - 支持不同版本 `API`
    - 允许用户选择不同版本
- 数据存储
    - `Etcd` 交互，负责持久化存储集群状态和配置文件
    - 出路所有对 `Etcd` 的读写请求，确保数据一致性和高可用
- `Watch` 机制
    - 支持客户端订阅对象变化，实现实时更新通知
    - 允许系统组件基于资源变化进行响应
- `API` 速率
    - 实现请求速率限制，确保稳定性和性能

###### `kube-controller-manager`

一组控制器集合，用于监控和管理集群中的各种资源，负责监视这些资源的变化，并采取相应的操作，确保资源处于期望状态

- 控制器，运行无限控制循环的程序
    - 节点控制器
    - 副本控制器
    - 服务控制器
    - 端点控制器
- 启动命令 `--controllers`
    - 启动时，可以通过命令行选项，来控制开启或者禁用哪些 `controller`

###### `cloud-controller-mananger`

云平台 `API` 接口和 `Kubernetes` 集群之前的桥梁，集群核心组件可以独立工作，也允许通过插件方式和云提供商集成

- 云平台控制器，保障 `cloud` 组件符合预期
    - `Node controller`
        - 通过和云提供商 `API`，更新节点相关信息
    - `Route controller`
        - 负责云平台上配置网络路由，使得不同节点之间可以相互通信
    - `Service controller`
        - 负责服务部署负责均衡器，分配 `IP` 地址
- 使用场景
    - 负载均衡器类型服务
        - 提供一个特定云负载均衡器，并和 `Kubernetes Service` 集成
        - 云存储方案为 `Pod` 提供存储卷

###### `kube-sheduler`

负责将新创建的 `Pod` 调度到集群中的节点上，它负责监视新创建的，未指定运行的 `Node` 的 `Pods`，选择节点让 `Pod` 在上面运行

###### `etcd`

分布式键值存储系统，用于存储集群的配置数据和状态信息，提供高可用性和一致性
`Etcd` 采用 `Raft` 共识算法，具有较强的一致性和可用

- 强一致性
    - 一个节点进行更新，强一致性确保它立即更新到集群中所有的其他节点
    - `CAP` 定理
        - 在遇到网络分区时，系统必须选择是牺牲一致性（返回不一样的数据），还是牺牲可用性（放弃一部分请求）
- 分布式
    - 被设计成保留强一致性的前提，作为一个集群在多个节点上运行
- 键值存储
    - 将数据存储为键和值的非关系型数据库，公开一个键值 `API`，数据存储构建在 `BlotDB`
- 作用
    - 存储 `Kubernetes` 对象的所有配置，状态和元数据
        - `Pods`
        - `Secrets`

### 数据面组件

数据面是指与集群内部运行的 `Pods` 及其网络、存储和其他服务直接关联的相关部分
数据面主要关注是处理应用程序的实际运行和数据流

- `kubelet`
- `kube-proxy`
- `container runtime`

###### `kubelet`

运行在每个节点上的代理程序，负责管理和监控节点上的容器
和 `kube-apiserver` 通信，接收来自控制平面的指令，根据指令创建，启动，停止和销毁容器；负责监控容器的状态和健康状况

负责容器真正运行的核心组件

- 负责 `Node` 节点上 `Pod` 的创建等全生命周期的管理
- 定时上报本地 `Node` 状态信息给 `kube-apiserver`
- `kubelet` 是 `Master` 和 `Node` 之间的桥梁，接收 `kube-apiserver` 分配给他们的任务并执行
- `kubelet` 通过 `kube-apiserver` 间接和 `Etcd` 交互来读取集群配置信息
- `kubelet` 在 `Node` 主要工作
    - 设置容器的环境变量，给容器绑定 `Volume` 和 `Port`
    - 为 `Pod` 创建，更新和删除容器
    - 负责存活（`Liveness`），就绪（`Readiness`）和启动（`Startup`）探针
    - 读取 `Pod` 配置，在主机为卷挂载创建相对应的目录来挂载

`kubelet` 除了可以接收来自 `kube-apiserver` 的 `Pod` 资源定义外，还可以接收来自文件，`HTTP` 端口和 `HTTP` 服务的 `Pod` 定义

##### `kube-proxy`

`kube-proxy` 负责为 `Pod` 提供网络代理和负载均衡功能 ，维护集群中网络规则和转发表，并将请求转发到合适目标的 `Pod` 上

支持多种代理模式

- 用户空间代理
- `iptables` 代理
- `IPVS` 代理

`kube-proxy` 是集群中每个节点 （`Node`）上所运行的网络代理，是一个 `Kubernetes Daemonset`
实现了 `Kubernetes Services` 概念的代理组件，为每组 `Pod` 提供具有负载均衡的 `DNS`

- 主要代理
    - `UDP`
    - `TCP`
    - `SCTP`

##### `container runtime`

容器运行时是负责在节点上创建和管理容器，主要为拉取镜像，启动容器等，并提供容器隔离和资源管理

支持的容器运行时必须实现 `CRI` 接口，这是一个插件接口，使得 `kubelet` 可以使用各种容器运行时

- `Docker`
- `containerd`
- `CRI-O`

# 术语

### `Resource`

`Kubernetes` 中大部分都可以看作是资源对象，`Node`、`Pod` 等，几乎所有的资源对象都可以通过 `kubectl` 命令进行管理

### `Kubernetes API version`

`kubectl api-versions` 查看 `api`，大致被分为三类，`alpha`、`beta`、`stable`

### `Pod`

最重要的概念，它是 `Kubernetes` 的最小调度单位， 每个 `Pod` 都有一个特殊的被称为根容器的 `Pause` 容器，除此之外还包含一个或者多个用户业务容器
`Pod` 支持将多个容器部署在同一个 `Pod`，他们共享 `pause` 容器的 `IP` 和 `voulume`，解决关联容器之间通讯和数据共享问题
引入 `Pause` 根容器是因为如果一个 `Pod` 中包含多个业务容器，`Kubernetes`
无法对整体状态进行正确判断，使用根容器的状态来判断 `Pod` 的状态

每个 `Pod` 都会被分配唯一的 `IP` 地址，多个容器共享 `Pod IP`，底层网络需要支持任意两个 `Pod` 之间 `TCP/IP` 直接通讯

- 普通 `Pod`
    - 创建之后会被存放在 `etcd` 中，随后被调度到具体的 `node` 节点上运行
    - 默认情况下，`pod` 中的某个容器停止运行时，`K8S` 会自动检测并重新启动，如果 `node` 宕机，会在其他 `node` 节点上该 `pod`
- 静态 `Pod`
    - 被存放在某个具体 `Node` 上具体文件中，并且只在该 `Node` 上启动，不能被调度到其他节点

### `Label`

一个 `Label` 是一个 `key=value` 的键值对，是由用户自己指定的，被附加到各种资源对象上
一个资源对象可以定义任意数量的 `Label`，同一个 `Label` 也可以被添加到任意数量的资源上
通过给指定资源对象绑定 `Label` 从而实现资源对象的分组管理，例如（版本标签，环境标签）

通过为资源对象贴上对应的标签，随后通过 `Label selector` 查询和筛选拥有标签的资源对象

- `name=xxx`
- `name in (xxx, xxx)`

### `Replication Controller / RC` (不推荐)

定义了一个期望场景，声明某种 `Pod` 副本数量任何时候都符合某一预期值

- `Pod` 期待的副本数量
- 用于筛选目标 `Pod` 的标签选择器
- 当 `Pod` 副本数量少于目标值，用于创建的模板

### `Replica Set`

`RC` 升级版本，`RC` 的标签选择器只支持基于等式的表达式，`RS` 支持基于集合
在线编辑 `RS` 之后，会自动更新 `Pod`，`RC` 不会自动更新现有的 `Pod`

### `Deployment`

为了更好的解决 `Pod` 的部署，升级和回滚等问题

- `Deployment` 会自动创建 `RS` 资源对象来完成部署，对 `Deployment` 的修改会产生新的 `RS` 资源对象，为新的发布版本服务
- 支持查看部署进度，确定部署操作是否完成
- 更新 `Deployment` 会触发部署从而更新 `Pod`
- 支持 `Pause` 操作，暂停之后对 `Deployment` 的修改不会触发发布动作，使用 `Resume` 操作可以继续发布
- 支持回滚
- 支持重启，会触发 `Pod` 更新
- 自动清理

### `Horizontal Pod Autoscaler / HPA`

用于 `Pod` 的横向自动收缩，根据追踪和分析指定 `RC/RS` 控制所有目标 `Pod` 负载变化，以此确定是否需要调整副本数量

### `StatefulSet`

`Pod` 管理的对象都是面向无状态的服务，但是很多服务是有状态，`StatefulSet` 就是用来管理有状态的服务
和 `Deployment` 类似，`StatefulSet` 也是通过标签选择器来管理一组相同定义的 `Pod`，`StatefulSet` 为每一个 `Pod`
维护了一个唯一的 `ID`

使用 `StatefulSet` 情况

- 需要稳定，唯一的网络标识的应用程序
- 需要持久化存储的应用程序
- 需要有序部署，更新缩放
- 常使用
    - `Mysql`
    - `MongoDB`
    - `kafka`

限制

- `Pod` 的存储必须由 `PersistentVolume` 驱动
- 删除或者收缩 `StatefulSet` 不会删除关联的存储卷
- 需要使用 `Headless Service` 来负责 `Pod` 的网络标识，需要创建 `Headless Service`
- 删除 `StatefulSet`，不保证删除管理的 `Pod`

### `DaemonSet`

确保全部或者某些节点运行一个 `Pod` 副本，当节点加入集群时，也会为他们新增一个 `Pod`
当节点从集群移除时候，这些 `Pod` 会被回收，删除 `DaemonSet` 会删除它创建的所有 `Pod`

- 常规用法
    - 每个节点上运行集群守护进程
    - 每个节点上运行日志收集程序
    - 每个节点上运行监控守护进程

### `Service`

将运行的在一组 `Pods` 上的应用程序公开为网络服务，这就是微服务
通过 `service` 资源对象定义一个访问入口，`service` 一旦被定义就会被分配一个不可变更的 `Cluster IP`

### `Job`

工作任务，`Job` 会创建一个或者多个 `Pods`，来执行工作任务，`Job` 会跟踪记录成功完成的 `Pods` 数量，数量达到指定成功个数，任务结束
执行过程中 `Pod` 出现失败，会创建新的 `Pod` 来替代
删除会清除创建的所有 `Pods`
挂起会删除所有活跃的 `Pods`，直到 `Job` 再次恢复执行

### `Volume`

`K8S` 抽象出来的对象，用来解决 `Pod` 容器运行时，文件存放以及多容器数据共享问题；核心是一个目录，`Pod` 中的容器可以访问该目录中的数据

`Pod` 可以使用任意数量的 `Volume` 类型，无论是什么数据类型重启期间数据都不会丢失，即卷的生命周期和容器无关

- 临时卷
    - 生命周期和 `Pod` 相同
- 持久卷
    - 生命周期和 `Pod` 无关

### `Persistent Volume / PV`

持久卷是集群中的一块存储，可由管理员事先供应或者使用存储类动态供应
持久卷是集群资源，类似节点是使用 `Volume` 插件来实现的，拥有独立的生命周期

`Pod` 通过 `PersistentVolumeClaim/PVC` 来申领 `PV` 作为存储卷使用，集群通过 `PVC` 找到其绑定的 `PV` 并挂载到 `Pod`

状态

- `Available`
    - 空闲
- `Bound`
    - 已绑定到 `PVC`
- `Released`
    - 对应 `PVC` 已经删除，但是资源还没被集群回收
- `Failed`
    - `PV` 自动回收失败

### `Namespace`

命名空间，主要提供资源隔离，通过命名空间可以将同一个集群中的资源划分为相互隔离的组。命名空间作用仅针对于那些带有命名空间资源对象
统一命名空间下的资源名必须唯一

### `Annotation`

注解和标签类似，也是使用键值对的形似来定义，标签是 `K8S` 对象的元数据，主要用于标签选择器；注解是用户随意定义的信息，主要方便外部工具查找

### `ConfigMap`

将其他资源对象所需要使用的非机密配置项的数据保存到键值对中

### `Secret`

类似 `ConfigMap`，但是是用来保存机密数据
