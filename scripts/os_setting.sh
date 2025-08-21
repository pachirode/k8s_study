# 关闭防火墙，清理防火墙规则，设置默认转发策略
function os::setting::stop-firewall() {
    systemctl stop nftable
    systemctl disable nftable
    sudo /usr/sbin/iptables -F && sudo /usr/sbin/iptables -X && sudo /usr/sbin/iptables -F -t nat && sudo /usr/sbin/iptables -X -t nat
    sudo /usr/sbin/iptables -P FORWARD ACCEPT
}

# 关闭 swap 分区，否则 kubelet 会启动失败 （设置 kubelet 启动参数 --fail-swap-on false 关闭 swap 检查）
function os::setting::stop-swap() {
    sudo swapoff -a
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
}

# 关闭 SELinux，负责 kubelet 挂在目录可能显示权限不足
function os::setting::stop-selinux() {
    sudo setenforce 0
    sudo sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config
}

# 优化内核参数，关闭 net.ipv4.tcp_tw_recycle=0，负责和 NAT 冲突，导致服务不通
function os::setting::sysctl() {
  cat > kubernetes.conf <<EOF
net.ipv4.ip_forward=1
net.ipv4.neigh.default.gc_thresh1=1024
net.ipv4.neigh.default.gc_thresh2=2048
net.ipv4.neigh.default.gc_thresh3=4096
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
fs.file-max=52706963
fs.nr_open=52706963
net.ipv6.conf.all.disable_ipv6=1
EOF

sudo cp kubernetes.conf /etc/sysctl.d/kubernetes.conf
sudo /usr/sbin/sysctl -p /etc/sysctl.d/kubernetes.conf
}

# 设置时间
function os::setting::time() {
  # 时区
  timedatectl set-timezone Asia/Shanghai
  # 时钟同步
  systemctl enable chrony
  systemctl start chrony
  # 当前 UTC 时间写入硬件
  timedatectl set-local-rtc 0
  # 重启依赖系统时间的服务
   for log_service in rsyslog syslog-ng systemd-journald; do
      if systemctl list-unit-files | grep -q $log_service; then
        systemctl try-restart $log_service
        break
      fi
  done
  systemctl restart chrony
  # 关闭无关服务
  if systemctl list-unit-files | grep -q postfix; then
      systemctl stop postfix
      systemctl disable postfix
  fi
}