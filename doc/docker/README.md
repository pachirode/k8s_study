# 资源配额

通过 `cgroup` 来控制容器使用的资源限制

- CPU
- 内存
- 磁盘

### 配置参数

`docker run --help | grep cpu-shares`

- `cpu`
    - `cpu-shares`
        - 不能保证可以获取到指定数量的资源，这仅仅是一个弹性加权
        - 默认值：1024，在同一个核心，同时运行多个容器加权效果才能体现
    - `cpuset-cpus`
        - 指定 `CPU`
- `memory`
    - `-m` `--memory`
- `IO`
    - 限制设备上的读写速度

> 两个参数同时使用，如果不是在一个核心，`cpu-shares` 失效

### 测试

##### CPU

限制两个容器分别只能运行在 `cpu0` 和 `cpu1`

```bash
docker run -itd --cpuset-cpus="0,1" --name docker10 --cpu-shares=512 pachirode/stress:v1 /bin/bash
docker run -itd --cpuset-cpus="0,1" --name docker20 --cpu-shares=1024 pachirode/stress:v1 /bin/bash
```

测试结果，两个核心全部跑满，暂用的 `CPU` 份额呈现二倍关系

##### IO

```bash
docker run -it -v ./tmp:/var/tmp --device=/dev/sda:/dev/sda --device-write-bps /dev/sda:2mb debian
time dd if=/dev/sda of=/var/tmp/test.out bs=2M count=50 oflag=direct,nonblock
# 81788928 bytes (82 MB, 78 MiB) copied, 39.0123 s, 2.1 MB/s
```

# 网络

### 网络模式

启动容器参数 `docker run --net==`

- `bridge`
  - 默认设置
  - 容器启动之后会通过 `DHCP` 获取一个 `IP`
- `host`
  - 共享物理机
- `none`
  - 启动容器没有 `IP`
  - 只有一个 `loopback`
- `container`
  - `--net==container:Name or ID`
    - 启动容器和已经存在的容器共享网络
- `overlay`
  - 不同宿主机上面的容器进行通讯
- `macvlan`
  - 分配 `MAC` 地址，模拟真实物理机

`docker` 在创建的时候会生成一个虚拟网桥 `docker0`
- 可以设置 `IP` 地址
- 相当于一个隐藏的虚拟网卡

每当运行一个容器时，会生成一个 `veth` 设备对，这个 `veth` 一个接口在容器里面一个在宿主机

### 设置别名

实现不同容器通过容器名或别名互连
- 启动时候加入 `--link` 参数
  - 目前已经被废弃
- 进入容器之后，修改 `/etc/host` 配置文件
- 用户自定义 `bridge` 网桥