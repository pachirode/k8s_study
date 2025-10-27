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

