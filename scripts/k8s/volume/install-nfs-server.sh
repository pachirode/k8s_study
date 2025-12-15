#!/usr/bin/env bash


# 安装 NFS Server
sudo apt update
sudo apt install -y nfs-kernel-server

# 写入配置文件，当前默认共享 /tmp/nfs/data 目录
mkdir -p /tmp/nfs/data
chmod 777 /tmp/nfs/data
echo '/tmp/nfs/data *(rw,sync,no_root_squash,no_subtree_check,fsid=0)' | sudo tee /etc/exports

# 启动 nfs 并使用最新配置
sudo systemctl enable nfs-server --now
exportfs -r
exportfs -v
