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

使用 `kubeadm` 创建和配置，通过 `Kubeadm Config Patches` 机制提供各种配置 [Configuration](https://kind.sigs.k8s.io/docs/user/configuration/)
[Configuration_example](config/example/kind/Configuration.yaml)
