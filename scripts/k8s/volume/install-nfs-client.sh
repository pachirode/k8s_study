#!/usr/bin/env bash

# 安装
apt update
apt install -y nfs-common

# 验证
mount.nfs -V

# 测试挂载
mount -t nfs 192.168.52.133:/tmp/nfs/data /mnt/test-nfs
df -h | grep nfs
umount /mnt/test-nfs