```bash
# 查看分区情况
df -h
Filesystem      Size  Used Avail Use% Mounted on
udev            7.8G     0  7.8G   0% /dev
tmpfs           1.6G  1.4M  1.6G   1% /run
/dev/sda1        47G   41G  3.1G  94% /

sudo fdisk -l
[sudo] password for master:
Disk /dev/sda: 100 GiB, 107374182400 bytes, 209715200 sectors
Disk model: VMware Virtual S

# fdisk 删除旧分区，创建新分区
sudo fdisk /dev/sda

欢迎使用 fdisk (util-linux 2.33.1)。
更改将停留在内存中，直到您决定将更改写入磁盘。
使用写入命令前请三思。

命令(输入 m 获取帮助)：d
分区号 (1,2,5, 默认  5): 2

分区 2 已删除。

命令(输入 m 获取帮助)：d
已选择分区 1
分区 1 已删除。

命令(输入 m 获取帮助)：n
分区类型
   p   主分区 (0个主分区，0个扩展分区，4空闲)
   e   扩展分区 (逻辑分区容器)
选择 (默认 p)：p
分区号 (1-4, 默认  1): 
第一个扇区 (2048-209715199, 默认 2048): 
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-209715199, 默认 209715199): 201326591

创建了一个新分区 1，类型为“Linux”，大小为 96 GiB。
分区 #1 包含一个 ext4 签名。

您想移除该签名吗？是[Y]/否[N]：y

写入命令将移除该签名。

命令(输入 m 获取帮助)：n
分区类型
   p   主分区 (1个主分区，0个扩展分区，3空闲)
   e   扩展分区 (逻辑分区容器)
选择 (默认 p)：p
分区号 (2-4, 默认  2): 
第一个扇区 (201326592-209715199, 默认 201326592): 
Last sector, +/-sectors or +/-size{K,M,G,T,P} (201326592-209715199, 默认 209715199): 

创建了一个新分区 2，类型为“Linux”，大小为 4 GiB。

命令(输入 m 获取帮助)：t
分区号 (1,2, 默认  2): 
Hex 代码(输入 L 列出所有代码)：82

已将分区“Linux”的类型更改为“Linux swap / Solaris”。

命令(输入 m 获取帮助)：a
分区号 (1,2, 默认  2): 1

分区 1 的 可启动 标志已启用。

命令(输入 m 获取帮助)：p
Disk /dev/sda：100 GiB，107374182400 字节，209715200 个扇区
Disk model: Virtual disk    
单元：扇区 / 1 * 512 = 512 字节
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
磁盘标签类型：dos
磁盘标识符：0xca5ca606

设备       启动      起点      末尾      扇区 大小 Id 类型
/dev/sda1  *         2048 201326591 201324544  96G 83 Linux
/dev/sda2       201326592 209715199   8388608   4G 82 Linux swap / Solaris

Filesystem/RAID signature on partition 1 will be wiped.

命令(输入 m 获取帮助)：w
分区表已调整。

# 重启之后执行分区扩大命令
sudo resize2fs /dev/sda1
```