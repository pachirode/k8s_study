#!/usr/bin/env bash

# ==============================================================================
# Hostname 相关的全局变量
# ==============================================================================

function os::mkdir() {
  sudo mkdir -p /opt/k8s/{bin,work} /etc/{kubernetes,etcd}/cert
}


readonly HOSTNAME="${HOSTNAME:-k8s}"
readonly HOSTNAME_MASTER_IP="${HOSTNAME_MASTER_IP:-192.168.29.130}"
readonly HOSTNAME_K8S_IP="${HOSTNAME_MASTER_NAME:-192.168.29.131}"
readonly HOSTNAME_NODE_IP="${HOSTNAME_NODE1_IP:-192.168.29.132}"

# 生成 EncryptionConfig 需要的 key
export ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

export NODE_IPS=(192.168.29.130 192.168.29.131 192.168.29.132)
export NODE_NAMES=(k8s-master k8s-01 k8s-02)

# etcd 集群服务地址
export ETCD_ENDPOINTS="https://192.168.29.130:2379,https://192.168.29.131:2379,https://192.168.29.132:2379"
export ETCD_NODES="k8s-master=https://192.168.29.130:2380,k8s-01=https://192.168.29.131:2380,k8s-02=https://192.168.29.132:2380"

# kube-apiserver 的反向代理 （kube-nginx）地址端口
export KUBE_APISERVER="https://127.0.0.1:8443"

# 节点间互联网络名称
export IFACE="eth0"

# etcd 数据目录
export ETCD_DATA_DIR="/data/k8s/etcd/data"

# etcd WAL 目录， SSD 或者 ETCD_DATA_DIR 不同的磁盘分区
export ETCD_WAL_DIR="/data/k8s/etcd/wal"

# k8s 各个组件数据目录
export K8S_DIR="/data/k8s/k8s"

## DOCKER_DIR 和 CONTAINERD_DIR 二选一
# docker 数据目录
export DOCKER_DIR="/data/k8s/docker"

# containerd 数据目录
export CONTAINERD_DIR="/data/k8s/containerd"

## 以下参数一般不需要修改

# TLS Bootstrapping 使用的 Token，可以使用命令 head -c 16 /dev/urandom | od -An -t x | tr -d ' ' 生成
BOOTSTRAP_TOKEN="dcd12089f71de95fd55415d918bf22bb"

# 最好使用 当前未用的网段 来定义服务网段和 Pod 网段

# 服务网段，部署前路由不可达，部署后集群内路由可达(kube-proxy 保证)
SERVICE_CIDR="10.254.0.0/16"

# Pod 网段，建议 /16 段地址，部署前路由不可达，部署后集群内路由可达(flanneld 保证)
CLUSTER_CIDR="172.30.0.0/16"

# 服务端口范围 (NodePort Range)
export NODE_PORT_RANGE="30000-32767"

# kubernetes 服务 IP (一般是 SERVICE_CIDR 中第一个IP)
export CLUSTER_KUBERNETES_SVC_IP="10.254.0.1"

# 集群 DNS 服务 IP (从 SERVICE_CIDR 中预分配)
export CLUSTER_DNS_SVC_IP="10.254.0.2"

# 集群 DNS 域名（末尾不带点号）
export CLUSTER_DNS_DOMAIN="cluster.local"

# 将二进制目录 /opt/k8s/bin 加到 PATH 中
export PATH=/opt/k8s/bin:$PATH

function os::export::environment() {
    for node_ip in "${NODE_IPS[@]}"; do
        scp environment.sh root@${node_ip}:/opt/k8s/bin
    done
}