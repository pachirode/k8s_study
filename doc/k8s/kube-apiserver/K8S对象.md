# 对象

### 资源对象

一条记录就是一个资源对象，代表集群期望或者当前某个实体状态
资源对象就是资源的具体实例对象

- 持久化到 `etcd`
- `API server` 暴露 `REST` 端点
- 案例
    - `Pod`
    - `Deployment`
    - `Service`

### 对象

和资源对象基本等价，多指单个 `API` 资源实例

- `Pod` 是资源，`nginx-pod-123` 是对象

##### 对象属性

对象结构体里面的字段

##### 资源元数据

描述对象的信息

- `TypeMeta`
- `ObjectMeta`

### ***`runtime.Object`***

`runtime.Object` 用来代表 `Kubernetes` 对象，表示对象的通用类型，有两种类型：单个对象和列表对象

一个 `K8S` 对象一定实现的核心方法
- `SetGroupVersionKind`
- `GroupVersionKind`
- `DeepCopyObject`

##### 接口实现 `metav1.TypeMeta`

```go
// Object interface must be supported by all API types registered with Scheme. Since objects in a scheme are
// expected to be serialized to the wire, the interface an Object must provide to the Scheme allows
// serializers to set the kind, version, and group the object is represented as. An Object may choose
// to return a no-op ObjectKindAccessor in cases where it is not expected to be serialized.
type Object interface {
GetObjectKind() schema.ObjectKind // 返回对象的类型信息，schema.ObjectKind 接口用于描述，API 对象的类型和版本信息
DeepCopyObject() Object // 创建对象的深层拷贝副本
}

type ObjectKind interface {
    // SetGroupVersionKind sets or clears the intended serialized kind of an object. Passing kind nil
    // should clear the current setting.
    SetGroupVersionKind(kind GroupVersionKind)
    // GroupVersionKind returns the stored group, version, and kind of an object, or an empty struct
    // if the object does not expose or provide these fields.
    GroupVersionKind() GroupVersionKind
}

type GroupVersionKind struct {
    Group   string // 资源组
    Version string // 资源版本
    Kind    string // 资源类型
}
```

##### 实现对象

- 定义资源对象内嵌 `metav1.TypeMeta`
  - 实现 `GetObjectKind()`
- 结构体前面添加注释
  - `// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object` 使用代码生成器，生成深度拷贝方法

##### 接口实现 `metav1.ObjectMeta`

资源的元数据，所有的资源对象都具有统一的元数据（资源 `List` 除外）

###### `meta.Accessor`
从 `runtime.Object` 类型获取 `metav1.Object` 接口对象



# 定义 `Kubernetes` 资源对象

最核心的一步是资源定义，`API` 接口的请求方法和请求路径在 `Kuberbetes` 中会根据资源定义自动生成

`Kubernetes` 对象是持久化的实体，使用这些实体去表示这个集群的状态

- 包含的信息
    - 哪些容器化的应用在哪个节点上运行
    - 可以被应用使用的资源
    - 应用运行策略
        - 重启
- 特点
    - 一旦对象被创建，系统持续工作保证对象存在
        - 创建对象本质上是在告知系统，期望的工作负载
    - 需要使用 `K8S API` 操作对象
    - 对象具有固定的格式

### 资源对象的标准格式

- 类型元数据
    - `metav1.TypeMeta`
    - 必须字段，定义资源使用的资源组，资源版本和资源类型
- 资源元数据
    - `metav1.ObjectMeta`
    - 必须字段，储存资源的元数据
        - 名称
        - 命名空间
        - 标签
- 资源期望状态定义
    - `Spec`
    - 必须字段，对象规约，定义对象期望的状态，字段描述了对象的配置和期望状态
- 资源当前状态定义
    - `Status`
    - 可选，描述对象当前状态
    - 通过由 `Controller`，根据对象的当前状态，来设置并更新

##### `XXXStatus`

- `Phase`
    - 表示资源当前的生命周期阶段
        - `Pending`
        - `Running`
    - 很多资源不需要该字段，常用类型为 `string` 也可以是自定义类型
- `ObservedGeneration`
    - 资源最后一次变化的版本，控制器用来检测资源是否响应
- `Conditions`
    - 提供资源当前状态的详细信息
    - 字段类型为数组
        - 执行 `PATCH` 操作时，通常策略为 `merge`

### 资源列表对象

表示资源的列表