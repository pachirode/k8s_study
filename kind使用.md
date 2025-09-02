# `Kind` 介绍

需要在宿主机安装 `Docker`

### 核心功能

- 支持多个 `Kubernetes` 节点（集群 `HA`，创建多个 `control-plane` 类型 `Node`）
- 创建的集群经过 `Kubernetes` 一致性验证

### 命令安装

##### 二进制安装

[install_kind.sh](scripts/kind/install_kind.sh)

### 集群配置

提供丰富的配置选择，有集群集别也有节点级别

使用 `kubeadm` 创建和配置，通过 `Kubeadm Config Patches`
机制提供各种配置 [Configuration](https://kind.sigs.k8s.io/docs/user/configuration/)
[Configuration_example](config/example/kind/Configuration.yaml)

### 端口映射

在测试开发的过程中，我们在集群中部署了一个 `Deployment`，并为该 `Deployment` 创建一个 `NodePort` 类型的 `Service`
宿主机上无法访问 `Service` 中配置的 `NodePort` 端口，进而访问 `Pod` 端口
`Service` 中配置的 `NodePort`是监听在 `Kubernetes` 节点容器，而非宿主机

`Kind` 支持 `extraPortMappings` 配置项，用来将宿主机的端口映射到 `Kubernetes`
节点容器上的某个端口，从而实现宿主机访问 `Kubernets` 访问宿主机访问节点容器端口，进而访问 `Kubernets Pod` 端口

```yaml
 extraPortMappings:
   # 节点端口 nodeport
   - containerPort: 32080 # 对应到 traefik web.nodePort
     # 宿主机端口
     hostPort: 18080
     # 宿主机端口监听地址，需要外部访问设置为"0.0.0.0"
     listenAddress: "0.0.0.0"
     # 通信协议
     protocol: TCP
   - containerPort: 32443 # 对应到 traefik websecure.nodePort
     hostPort: 18443
     listenAddress: "0.0.0.0"
     protocol: TCP
```

### 暴露 `Kube-apiserver`

在测试开发过程中，我们想在 B 机器访问 A 机器上的 `Kind` 集群，会无法访问
默认情况下，`Kind` 集群的 `Kube-apiserver` 监听在 A 机器上的 lo 网络设备上的，并且监听端口也是随机的
如果想要外界访问，需要使 `Kube-apiserver` 监听在可访问的网络设备 `eth0` 的某个端口

```yaml
networking:
  # 绑定到宿主机上的地址，如果需要外部访问请设置为宿主机 IP
  # 注意：这里需要设置为你的宿主机 IP 地址
  apiServerAddress: 192.168.0.100
  # 绑定到宿主机上的端口，如果建多个集群或者宿主机已经占用需要修改为不同的端口
  apiServerPort: 6443
```

### 启用 `Feature Gates`

支持 `Feature Gates`，我们可以开启或者关闭 `Feature Gates` 来开启或者关闭某些功能

```yaml
featureGates:
  "CSIMigration": true
```

### 常用命令

##### kind -h

查看 `kind` 工具支持的命令

##### kind create cluster [flags]

创建 `kind` 集群

```bash
# 创建一个本地测试的集群
kind create cluster -n test-k8s

kind create cluster -h
```

##### kind get

查询集群信息

- 获取 `kind` 集群列表
- 获取指定集群 `Node` 列表
- 获取指定集群 `kubeconfig`

```bash
# 获取所有 kind 集群
kind get clusters

# 根据名字查询集群节点列表
kind get nodes -n test-k8s

# 查询所有集群的节点列表
kind get nodes -A

# 获取名为 test-k8s Kind 集群的 kubeconfig 文件内容
kind get kubeconfig -n test-k8s
```

##### kind export

导出集群 `kubeconfig` 文件和日志

```bash
# 导出名为 test-k8s Kind 集群的 kubeconfig，并保存到 /tmp/test-k8s 文件中
kind export kubeconfig -n test-k8s --kubeconfig /tmp/test-k8s

# 导出名为 test-k8s Kind 集群的日志到 test-k8s-log 目录中
kind export logs -n test-k8s test-k8s-log
```

##### kind load

通常我们会在开发机上使用 `docker build` 命令构建需要测试组件的镜像，构建的镜像在宿主机上没有进入节点容器

```bash
# 将 image:tag 镜像加载到名为 test 的 Kind 集群的所有节点上
kind load docker-image --name test image:tag

# 将镜像加载到指定的节点上
kind load docker-image --name test --nodes worker1 image:tag --nodes worker
```

##### kind delete

删除集群

```bash
kind delete cluster -n test-k8s
# 删除所有集群
kind delete clusters -A
```