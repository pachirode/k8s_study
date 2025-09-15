# 设计 `REST API` 接口

`kube-apiserver` 是一个 `Web` 服务，里面内置了 `REST` 资源

`kubectl api-resources |egrep 'k8s.io|batch| v1| apps| autoscaling| batch'` 查看 `kube-apiserver` 支持的资源，过滤掉第三方资源

`REST` 资源的设计

- 指定资源类型
    - 将功能抽象成一系列 `REST` 资源
    - `user`
    - `secret`
- 指定 `HTTP` 方法
- 设计 `API` 版本标识
    - `/v1/user` 最常用
    - `HTTP Header` 中
        - `Accept: vnd.example-com.foo+json; version=1.0`
        - `From` 参数中
            - `/users?version=v1`
- 请求参数和返回参数

### 标准 `RESTful API` 定义

尝试用的 `HTTP` 请求方法为 `GET`、`PUT`、`POST`、`DELETE`，映射为 `Go` 函数名为 `Get`，`List`，`Create`，`Delete`，`Update`
除此之外还要支持

- `DeleteCollection`
    - 删除多个资源对象
- `Patch`
    - 对资源对象进行部分更新的操作
- `Watch`
    - 监视资源对象变化

##### 资源组

支持资源组，可以称为 `API Group`，资源组是对 `REST` 资源按功能进行逻辑划分
具有相同功能类别的资源会划分到同一个资源组
`Deployment` 和 `StatefulSet` 资源因为都是创建一个工作负载，所有都归属于同一个 `apps` 资源组中

[案例](../../../demo/kube-apiserver/resource-group/main.go)

资源分组可以使得对分组资源统一进行中间件处理

##### `HTTP` 请求路径

由资源组，资源版本和资源类型共同构建

### 标准化资源定义

一般 `RESTful` 服务开发，`Post` 请求的 `Body` 需要自行定义，`K8S` 中 `Body` 也有固定格式

[案例](../../../demo/kube-apiserver/types.go)

- `TypeMeta`
    - 定义了资源使用的 `API` 版本
        - `v1`
        - `api/v1`
    - 定义了资源类型
        - `Pod`
        - `Service`
        - `Deployment`
- `ObjectMeta`
    - 存储资源的元数据
        - 名称
        - 命名空间
        - 标签
        - 注释
- `Spec`
    - 定义资源的期望状态
        - 每种类型的资源在 `spec` 中有特定的字段
- `Status`
    - 当前资源的状态
        - `K8S` 系统自动管理
    - 不是所有的资源都有该字段

### 资源版本转换

接口版本升级

- 同一个 `Web` 服务进程中，不同的路由
    - `Post /v1/pods`
    - `Post /v2/pods`
- 不同 `Web` 服务进程，相同路由
    - 修改服务
- `K8S`
    - 支持不同版本
    - 支持版本转换
    - 资源转换
        - `POST /api/v1` 和 `POST /api/v1beta1`
        - 最终都会转换为内部版本，再进行逻辑处理
        - 支持将旧版本的 `API` 资源转换为新版本的资源

`kube-apiserver` 处理完资源之后，保存在 `etcd` 中的是版本化资源数据

### 资源处理标准化

通用的逻辑处理

- 资源默认值设置
    - 用户请求中会携带大量参数，有些参数会有默认值
- 资源校验
    - 资源合法性校验

### 代码生成技术