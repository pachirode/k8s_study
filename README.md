# k8s_study

K8s 学习

# 部署 K8S 集群

### 配置

`Debain 13` 虚拟机

- `Master`
    - `4C 8G`
- `K8S`
    - `2C 4G`
- `Node`
    - `2C 4G`

### 策略

##### `kube-apiserver`

- 本地节点 `nginx` 四层透明代理实现高可用
- 关闭非安全 `8080` 和匿名访问
- 安全端口 `6443` 接收 `https` 请求
- 严格的认证和授权策略 (`x509` `Token` `RBAC`)
- 开启 `bootstrap` 认证，支持 `kubelet TLS bootstrapping`
- 使用 `https` 访问 `kubelet` `etcd` 加密通信

##### `kube-controller-manager`

- 3 节点高可用
- 关闭非安全端口，在安全端口 `10252` 接收 `https` 请求
- 使用 `kubeconfig` 访问 `apiserver` 的安全端口
- 自动 `approve kubelet CSR`，证书过期之后自动轮换
- 各 `contoller` 使用自己的 `ServiceAccount` 访问 `apiserver`

##### `kube-scheduler`

- 3 节点高可用
- 使用 `kubeconfig` 访问 `apiserver` 的安全端口

##### `kubelet`

- 使用 `kubeadm` 动态创建 `bootstrap token`，而不是 `apiserver` 中静态配置
- 使用 `TLS bootstrap` 机制自动生成 `client` 和 `server` 证书，过期之后自动轮换
- 在 `KubeletConfiguration` 类型的 `JSON` 文件配置主要参数
- 关闭只读端口，在安全端口 `10250` 接收 `https` 请求，对请求进行验证和授权
- 使用 `kubeconfig` 访问 `apiserver` 的安全端口

##### `kube-proxy`

- 使用 `kubeconfig` 访问 `apiserver` 的安全端口
- 在 `KubeProxyConfiguration` 配置文件中配置主要参数
- 使用 `ipvs` 代理模式

##### 集群插件

- `DNS`
- `Dashboard`
- `Metrics Server`
- `Log`
- `Registry`

# 安装

### cfssl

创建证书

### kubectl

k8s 命令行管理工具

### Ectd

基于 `Raft` 构建的分布式数据库，常用于服务发现，共享配置和并发控制

### 部署 Master 组件

这些组件均以多个实例模式运行，当 `leader` 挂了之后重新选举产生新的，保证服务的可用性
- `kube-apiserver`
- `kube-scheduler`
- `kube-controller-manager`
