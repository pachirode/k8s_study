`kube-apiserver` 本质上是一个标准的 `RESTful API` 服务器

# 定义 `API` 接口

将功能抽象成指定的 `REST` 资源，并给每一个资源指定请求路径和请求参数

- 请求路径
    - 标准的 `HTTP` 请求路径
        - `/api/v1/namespaces/{namespace}/pods`
- 请求参数
    - 根据 `HTTP` 请求方法不同，参数位置不同

### 路由设置

指定一个 `HTTP` 请求路径，由哪个函数来处理

- 路由创建
- 路由注册

### 开发路由函数

- 确认默认值
    - 有些请求参数没有被指定，未来确保请求能给按预期执行，需要设置合适的默认值
- 请求参数校验
    - 校验请求参数是否合法
- 逻辑处理

### 设置 `REST API` 接口

`kubectl api-resources |egrep 'k8s.io|batch| v1| apps| autoscaling| batch'` 查看支持的所有资源

- 指定 `REST` 资源类型

# 资源

### `APIResource`

代表一个[资源组](../../../demo/kube-apiserver/api_resource.go)

`Categories` 指定资源所属的资源分组，如果此处指定 `all`，使用 `kubectl get all` 就可以看到创建的自定义资源

### 资源类型 `Kind`

某一种资源归属于某一种类型，通常情况下一个资源归属于一个资源类型，但是某个资源的子资源可能归属于不同的资源类型

- `/api/v1/namespaces/default/deployment`
- `/api/v1/namespaces/default/deployment/scale`

资源分类

- `Workloads`
    - 工作负载，用来管理可以在集群节点上运行容器的资源对象
    - `Pod`
- `Discovery & LB`
    - 服务发现和负载均衡，用来将工作负载组合成一个外部可访问的，负载均衡服务的资源对象
    - `Service`
- `Config & Storage`
    - 配置和存储，用来注入初始化数据到应用程序中，并持久化存储容器外部的数据资源对象
    - `ConfigMap`
- `Cluster`
    - 集群，定义集群的本身配置方式，这些资源类型通常只会被集群管理员使用
    - `ResourceQuota`
- `Metadata`
    - 元数据，用来配置集群内其他资源行为的对象，用于扩展工作负载
    - `HorizontalPodAutoscaler`

### 资源组 `Group`

方便统一管理和维护所有资源，根据资源功能特性，抽象出资源组的概念，每个资源都归属于一个逻辑资源组

资源组类型

- 拥有组名的资源组
    - 请求 `/apis/<group>/<version>/<resource>`
    - 访问自定义的 `API` 组，扩展 `K8S API`
- 没有组名的资源组
    - `/api/<version>/<resource>`
    - 用来访问核心 `API` 组
        - `v1` 版本核心 `API` 对象
            - `Pod`
            - `Service`

资源和资源组在默认情况下被启用，通过给 `kube-apiserver` 设置 `--runtime-confi` 参数来启用或者禁用
参数为 `<key>[=<value>]` 如果省略值则为 `true`
修改资源或者资源组时，需要重启 `kube-apiserver` 和 `controller` 使得修改生效

### 资源版本 `Version`

表示 `API` 的资源版本，用于标识 `API` 资源的演变，采用了语义化版本规范

资源版本控制

- `Alpha`
    - `v1alpha1`
    - 默认被禁止，必须在 `kube-apiserver` 配置中显式启用
    - 新特性，会出现问题
    - 随时会被删除
- `Beta`
    - 新版本默认被禁止，需要显式启用
    - 可以被使用，功能将长期维护但是后续版本可以需要迁移
- `Stable`
    - 默认启用

资源版本分类

版本转换时，所有的具名版本会先转换为内部版本，内部版本再转换为其他具名版本
创建 `K8S` 资源时，必须指定一个资源版本，内部版本不对外暴露

- 内部版本
- 外部版本

### 根据 `Group Version Kind` 构建 `REST`

```bash
kubectl apply -f deployment.yaml --dry-run=client -o json > deployment.json
kubectl create --raw /apis/apps/v1/namespaces/default/deployments -f deployment.json
```

创建资源时，指定了 `URL`，如果不指定配置文件中已经指明 `apiVersion` `kind` 字段

- `Group`
    - `apps`
- `Version`
    - `v1`
- `Kind`
    - `deployment`

- `GV`
    - 资源组和版本，主要区分不同组和版本
- `GVK`
    - 资源组，版本和类型，唯一标识和定位一个具体的资源
        - `apps/v1/Deployment`
- `GVR`
    - 资源组，版本和资源名称，资源 `URL` 路径

# 支持 `HTTP` 接口

[路由构建](./路由构建.md)

### 客户端 `HTTP` 路由

通过 `SDK` 来访问 `kube-apiserver`，是由 `client-gen` 工具自动生成的，可以指定需要给资源生成的 `API` 操作

### 服务端 `HTTP` 路由

服务端的 `HTTP` 路由是由 `kube-apiserver` 在启动时，用静态代码的方式添加

```bash
actions = appendIf(actions, action{"LIST", resourcePath, resourceParams, namer, false}, isLister)
```

### 路由处理

[路由处理](./路由处理.md)

### 创建 REST Storage

`storage := map[string]rest.Storage{}` 保存每个资源的 `Storage`，其中 `key` 为资源名称
然后将资源保存到 `VersionedResourcesStorageMap` 中，最外层的 `key` 是资源版本

# 参数校验

- `createHandler` 函数是真正的请求处理函数
    - `r rest.NamedCreater`
        - 前面步骤生成的 `REST` 里面 `CreateStrategy` 字段包含了 `Validate` 方法用于进行参数的校验
    - `scope *RequestScope`
        - 封装 `RESTful` 中常见的处理方法
    - `admit admission.Interface`
        - `Kubernetes Admission Controller` 链，包含多个 `Admission Webhook` 插件，执行时会按照初始化顺序先后执行这些插件
- `CreateOptions`
    - 校验 `CreateOptions`，检验请求参数是否合法
- ***需要修改的部分***
    - 校验资源 `ObjectMeta.ManagedFields` 是否合法
    - 资源校验策略，可以执行自定义校验逻辑
    - 校验资源 `ObjectMeta` 字段是否合法
    - 执行 `Validating Webhook` 校验资源

# 设置默认值

- 设置默认值时间
  - 到达路由函数前
    - `k8s` 主要采用的方式，类似中间件的使用 
  - 参数验证过程中
  - 业务层处理

`k8s` 只会给版本化的 `API` 设置默认值，内部的 `API` 是不会设置默认值



# APIServer 分类

### AggregatorServer

负责处理 `apiregistration.k8s.io` 下面的资源请求，同时将请求拦截转发给 `Aggregated APIServer(AA)`

### KubeAPIServer

负责对请求的一些通用处理，认权，鉴权，内部资源访问

### ApiExtensionsServer

`CRD` 用户自定义资源的处理