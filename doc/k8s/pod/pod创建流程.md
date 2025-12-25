[测试案例](config/example/pod_create_flow)

# `kube-controller-amnage`

在启动 `kube-controller-manager` 时，`kube-controller-manager` 会和 `kube-apiserver` 建立连接，并通过 `Listen-Watch` 机制，监听 `kube-apiserver` 上的资源变化。
根据变更时间，调用对应的 `Handler` 来协调资源，`kube-apiserver` 保持连接，并在相关资源发生变化时通过流式响应的方式，将变更的信息推送给 `kube-controller-manager`

其他组件也是使用相同的方式来建立连接

# 创建 `ReplicaSet` 资源

用户使用 `kubectl` 工具调用 `kube-apiserver` 接口创建一个 `ReplicaSet` 资源

`kubectl create -f ReplicaSet.yaml -v 10`

- 加载 `kubeconfig` 文件，该文件指定连接 `kube-apiserver` 证书、访问地址等信息
- `kubectl -v = 10` 请求打印 `kube-apiserver` 中 `r` 的 `curl` 命令
- `kubectl` 访问 `kube-apiserver` 的 `Get /openapi/v3` 接口
  - 确定如何交互 (API 端点、请求和响应格式)

# `kube-apiserver` 将 `ReplicaSet` 资源创建数据写入 `etcd`

`kubectl` 调用请求创建 `ReplicaSet` 资源后，`kube-apiserver` 会对请求进行认证，鉴权，对资源设置默认值，准入控制，参数校验之后，将资源数据保存到 `etcd` 中

# `Etcd` 发送 `ReplicaSet` 创建对象给 `kube-apiserver`

# `kube-controller-manager` `Watch` 到 `ReplicaSet` 资源创建

# 创建 `Pod`

`kube-controller-manager ` 收到创建事件之后，会解析事件的对象数据即 `ReplicaSet` 创建的 `Pod` 模板数据

根据 `Spec` 定义进行资源调和

# `kube-apiserver` 将 `Pod` 资源创建数据写入 `etcd`

# `Etcd` 发送 `Pod` 创建事件给 `kube-apiserver`

# `kube-scheduler`  `Watch` 到 `kube-apiserver Pod` 创建事件

# `kube-scheduler` 调度 `Pod` 后，更新 `Pod` 资源

`kube-scheduler Watch` 到 `Pod` 创建事件之后，会解析事件的对象数据即 `Pod` 的资源定义
根据集群中节点个数及状态，将 `Pod` 调度到合适的节点上

# `kube-apiserver` 将 `Pod` 资源更新写到 `etcd`

# `Etcd` 发送一个 `Pod` 变更事件给 `kube-apiserver`

# `kubelet watch` 到 `kube-apiserver Pod` 变更事件，创建 `Pod`

`kubelet` 获取到资源变更之后，过滤掉不是当前节点的 `Pod` 资源的所有事件

解析 `Pod` 资源，调用底层容器运行时