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
