#!/usr/bin/env bash

function os::install::sudo() {
    CURRENT_USER=$(whoami)
    if [ "$CURRENT_USER" != "root" ]; then
        if groups $CURRENT_USER | grep -q "\bsudo\b"; then
          echo "User $CURRENT_USER already in sudo group"
        else
          read -s -p "Please enter root password to continue: " $ROOT_PASSWORD
          echo "$ROOT_PASSWORD" | su -c "usermod -aG sudo $CURRENT_USER" root
        fi
    else
      read -s -p "Please enter user need add sudo" $USER_NAME
      usermod -aG sudo $USER_NAME
    fi
}

function os::install::hostname() {
    hostnamectl set-hostname $HOSTNAME

    cat >> /etc/hosts <<EOF
127.0.0.1 localhost
127.0.1.1 $HOSTNAME
EOF
}

function os::install::ssh-server() {
    sudo apt-get install -y openssh-server
    sed -i 's/PublicKeyAuthentication no/PublicKeyAuthentication yes/g' /etc/ssh/sshd_config
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    sed -i 's/^#\s*\(AuthorizedKeysFile\s\+.*\)/\1/' /etc/ssh/sshd_config
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