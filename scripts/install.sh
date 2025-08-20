#!/usr/bin/env bash

function os::install::sudo() {
    CURRENT_USER=$(whoami)
    if [ "$CURRENT_USER" != "root" ]; then
        if groups $CURRENT_USER | grep -q "\bsudo\b"; then
          echo "User $CURRENT_USER already in sudo group"
        else
          read -s -p "Please enter root password to continue: " ROOT_PASSWORD
          echo "$ROOT_PASSWORD" | su -c "/usr/sbin/usermod -aG sudo $CURRENT_USER" root
        fi
    else
      read -s -p "Please enter user need add sudo" USER_NAME
      usermod -aG sudo $USER_NAME
    fi
}

function os::install::hostname() {
    hostnamectl set-hostname $HOSTNAME

    sudo cat >> /etc/hosts <<EOF

${HOSTNAME_MASTER_IP} k8s-master
${HOSTNAME_K8S_IP} k8s-01
${HOSTNAME_NODE_IP} k8s-02
EOF
}

function os::install::ssh-server() {
    sudo apt-get install -y openssh-server
    sudo sed -i 's/PubKeyAuthentication no/PubKeyAuthentication yes/g' /etc/ssh/sshd_config
    sudo sed -i 's/#PubKeyAuthentication no/PubKeyAuthentication yes/g' /etc/ssh/sshd_config
    sudo sed -i 's/#PubKeyAuthentication yes/PubKeyAuthentication yes/g' /etc/ssh/sshd_config

    sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    sudo sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config

    sudo sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config

    sudo sed -i 's/^#\s*\(AuthorizedKeysFile\s\+.*\)/\1/' /etc/ssh/sshd_config
    systemctl restart sshd
}

function os::install::cli-grub() {
    systemctl set-default runlevel3.target
#    systemctl set-default multi-user.target
}

function os::install::grap-grub() {
    systemctl set-default runlevel5.target
#    systemctl set-default graphical.target
}

function os::install::login-without-password() {
    # 生成SSH密钥对（如果不存在）
    if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ''
    fi

    # 确保SSH目录权限正确
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/id_rsa
    chmod 644 ~/.ssh/id_rsa.pub

    # 复制公钥到目标主机（如果主机可达）
    if ping -c 1 k8s-01 &> /dev/null; then
        ssh-copy-id root@k8s-01
    else
        echo "Warning: k8s-01 is not reachable"
    fi

    if ping -c 1 k8s-02 &> /dev/null; then
        ssh-copy-id root@k8s-02
    else
        echo "Warning: k8s-02 is not reachable"
    fi
}

function os::install::test-ssh() {
    echo "Testing SSH connections..."

    if ssh -o BatchMode=yes -o ConnectTimeout=5 root@k8s-01 echo "Connected to k8s-01"; then
        echo "✓ SSH to k8s-01 successful"
    else
        echo "✗ SSH to k8s-01 failed"
    fi

    if ssh -o BatchMode=yes -o ConnectTimeout=5 root@k8s-02 echo "Connected to k8s-02"; then
        echo "✓ SSH to k8s-02 successful"
    else
        echo "✗ SSH to k8s-02 failed"
    fi
}

function os::install::ENV() {
    echo "export PATH=/opt/k8s/bin:$PATH" >> $HOME/.bashrc
    source /root/.bashrc
}

function os::install::software() {
    sudo apt-get update && sudo apt install -y policycoreutils jq chrony conntrack ipvsadm ipset jq iptables curl sysstat wget socat git
}
