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

### 部署 Worker

- `kube-nginx`
- `containerd`
    - 如果想要使用 `docker` 需要配合 `flannel`
- `kubelet`
    - 接受 `kube-apiserver` 发送请求，管理 `Pod`，执行交互命令
- `kube-proxy`
- `cilium`

##### containerd 镜像

- 修改 `/etc/containerd/config.toml`，新版本已经废弃
    - 修改完需要 `systemctl restart containerd.service`
- 放到一个单独的文件夹中，并修改 `/etc/containerd/config.toml` `config_path`
    - 只需要第一次修改配置文件后重启

> `nerdctl` 命令来说，会自动使用 `/etc/containerd/certs.d` 目录下的配置镜像加速
> `ctr` 命令，需要指定 `--hosts-dir=/etc/containerd/certs.d`
> `ctr --debug=true -n k8s.io i pull --hosts-dir=/etc/containerd/certs.d registry.k8s.io/sig-storage/csi-provisioner:v3.5.0`

##### Bootstrap Token Auth 和授权

`kubelet` 启动时会查找 `--config` 参数对应的文件，如果不存在则使用 `--bootstrap-kubeconfig` 参数指定 `kubeconfig`
发送证书签名（`CSR`）
`kube-apiserver` 收到 `CSR` 请求之后，进行 `Token` 认证，认证通过 user = `system:bootstrap:<token-id>`,
group = `system:bootstrappers`
默认情况下，user 和 group 没有创建 `CSR` 的权限，需要创建 `ClusterRoleBinding`

```go
kubectl create clusterrolebinding kubelet-bootstrap --clusterrole = system:node-bootstrapper --group = system:bootstrappers
```

##### 自动 Approve CSR，生成 kubelet client 证书

`kubelet` 创建 `CSR` 请求之后，下一步需要创建被 `approve`

- `kube-controller-manager` 自动 `approve`
- 手动命令 `kubectl certificate approve <csr-name>`

`CSR` 被 `approve` 之后，`kubelet` 向 `kube-controller-manager` 请求创建 `client` 证书

### 部署网络组件

支持多种网络插件，生产环境中 `Cilium` 使用比较多；部署完网络插件还需要部署 `DNS` (`CoreDNS`)

### 部署 `Kubernetes Dashboard`

用来提供界面化访问 `Kubernetes` 集群

### 部署 `Prometheus`

`kube-prometheus` 是一整套监控解决方案，它使用 Prometheus 采集集群指标，Grafana 做展示，包含如下组件
- `The Prometheus Operator`
- `Highly available Prometheus`
- `Highly available Alertmanager`
- `Prometheus node-exporter`
- `Prometheus Adapter for Kubernetes Metrics APIs (k8s-prometheus-adapter)`
- `kube-state-metrics`
- `Grafana`

