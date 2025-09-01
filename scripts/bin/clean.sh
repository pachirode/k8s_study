function clean() {
  # 关闭相关进程
  sudo systemctl stop kubelet kube-proxy kube-nginx
  sudo systemctl disable kubelet kube-proxy kube-nginx

  # 停止容器
  crictl ps -q | xargs crictl stop
  killall -9 containerd-shim-runc-v1 pause

  # 停止 containerd
  systemctl stop containerd && systemctl disable containerd

  # 清理文件
  source environment.sh
  # umount k8s 挂载的目录
  mount |grep -E 'kubelet|cni|containerd' | awk '{print $3}'|xargs umount
  # 删除 kubelet 目录
  sudo rm -rf ${K8S_DIR}/kubelet
  # 删除 docker 目录
  sudo rm -rf ${DOCKER_DIR}
  # 删除 containerd 目录
  sudo rm -rf ${CONTAINERD_DIR}
  # 删除 systemd unit 文件
  sudo rm -rf /etc/systemd/system/{kubelet,kube-proxy,containerd,kube-nginx}.service
  # 删除程序文件
  sudo rm -rf /opt/k8s/bin/*
  # 删除证书文件
  sudo rm -rf /etc/flanneld/cert /etc/kubernetes/cert

  # 清理 kube-proxy 和 cilium 创建的 iptables
  sudo iptables -F && sudo iptables -X && sudo iptables -F -t nat && sudo iptables -X -t nat
}

function clean::master() {
  source environment.sh

  # 停止相关进程
  sudo systemctl stop kube-apiserver kube-controller-manager kube-scheduler

  # 删除 systemd unit 文件
  sudo rm -rf /etc/systemd/system/{kube-apiserver,kube-controller-manager,kube-scheduler}.service
  # 删除程序文件
  sudo rm -rf /opt/k8s/bin/{kube-apiserver,kube-controller-manager,kube-scheduler}
  # 删除证书文件
  sudo rm -rf /etc/flanneld/cert /etc/kubernetes/cert

  sudo systemctl stop etcd

  # 删除 etcd 的工作目录和数据目录
  sudo rm -rf ${ETCD_DATA_DIR} ${ETCD_WAL_DIR}
  # 删除 systemd unit 文件
  sudo rm -rf /etc/systemd/system/etcd.service
  # 删除程序文件
  sudo rm -rf /opt/k8s/bin/etcd
  # 删除 x509 证书文件
  sudo rm -rf /etc/etcd/cert/*
}