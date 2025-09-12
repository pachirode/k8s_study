`cgroup` 是 `Linux` 内核提供的一种资源管理和限制机制，主要用于对进程进行分组，并对分组内的进程进行资源限制，优先级调整等功能
提供一种统一的接口用来管理系统资源，比如 `CPU`、内存、IO、网络等资源，并管理这些资源的使用情况。

- `cgroup` 文件系统
    - 用来存储 `cgroup` 的配置信息和状态数据
- 子系统
    - 用来实现对特定资源的管理和限制
    - 一个子系统就代表一个资源控制器
- 控制组
    - 对进程进行分组，每个控制组可以关联一个或者多个子系统
- 层级
    - 控制组可以进行嵌套，子节点控制组会继承父节点资源的限制规则

`cgroup` 和 `namespace` 类似，但是主要作用不一样

- `cgroup` 对一组进程进行统一的资源管理
- `namespace` 是为了隔离进程组之间的资源

# 查看现有的资源隔离

常用的为 `CPU`, `Memory`, `blkio` (`I/O` 块设备)

```bash
ls /sys/fs/cgroup/ -al
```

# 系统资源

通过将 `cgroup` 和 `systemd` 单位树捆绑，可以把资源管理设置从进程级别移动至应用级别
默认 `systemd` 会自动创建 `slice` `scope` 和 `service` 单位层级

### CPU 资源划分

- 三个默认的顶级 `slice`
    - 三个 `cgroup`
        - `System`
            - 所有系统 `service` 的默认位置
        - `User`
            - 所有用户会话的默认位置
            - 每个用户会话都会在该 `slice` 下创建一个子 `slice`，如果同一个用户多次登录，会使用相同的子 `slice`
        - `Machine`
            - 所有虚拟机和 `Linux` 容器的默认位置
    - 每个 `slice` 都会获得相同的 `CPU` 使用时间，在 `CPU` 繁忙的时候
- `shares`
    - 设置 `CPU` 权重，针对每个控制组，默认为 `1024`
- 设置 `CPU` 资源限制
    - `cpu.cfs_period_us`
        - 统计 `CPU` 使用时间的周期，单位是微秒
    - `cpu.cfs_quota_us`
        - 周期内允许占用的 `CPU` 时间（单核时间，多核需要累加）

```bash
systemctl set-property user-1000.slice CPUQuota=20% # 设置 CPU 资源的使用上限

cat /sys/fs/cgroup/cpu,cpuacct/user.slice/user-1000.slice/cpu.cfs_period_us # 查看对应 `cgroup` 参数
```

通过配置文件来设置 `cgroup`，在对应的文件夹下创建配置文件；使用 `systemctl` 命令行工具设置的 `cgroup` 也会写到该目录下的配置文件中

- `service`
    - `/etc/systemd/system/xxx.service.d`
- `slice`
    - `/run/systemd/system/xxx.slice.d`

### 查看当前 `ccgroup`

- `systemd-cgls --no-page`
    - 返回系统整体 `cgroup` 层级，只提供层级的静态信息快照
- `systemd-cgtop`
    - 查看 `cgroup` 层级的动态信息，但是只显示了开启资源统计功能
    - 提供的统计数据和 `top` 命令类似

```bash
# 开启资源统计功能，会在  /etc/systemd/system/sshd.service.d/ 目录下创建对应的配置文件
systemctl set-property sshd.service CPUAccounting=true MemoryAccounting=true
```

### `cgroup` 内存

- 默认开启 `swap`
- `MemoryLimit` 参数，表示某个 `user` 或者 `service` 所能使用的物理内存的总量

```bash
systemctl set-property user-1001.slice MemoryLimit=200M
# 产生 8 个子进程，每个进程分配 256M 内存
stress --vm 8 --vm-bytes 256M
```
当物理内存不够，会触发 `memory.failcnt` 里面的数量加 1，但是进程不一定会被杀死，内核会尽量将物理内存中的数据迁移到 `swap` 空间中

# 案例

### 分配 `CPU` 相对使用时间，单核

测试对象，1 个 `service` 和两个普通用户

```bash
id going
uid=1001(going) gid=1001(going) groups=1001(going),994(docker)

# 创建 demo.service

systemctl start demo.service

# going
systemctl set-property user-1001.slice CPUShares=256
sha1sum /dev/zero

# test
sha1sum /dev/zero

top
PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
7071 root      20   0    5488    892    804 R  44.2   0.0   0:33.79 sha1sum
7090 test      20   0    5488    876    784 R  30.6   0.0   0:18.87 sha1sum
7884 going     20   0    5488    888    800 R  10.0   0.0   0:01.71 sha1sum

```

创建一个 [service](demo.service)

`/dev/zero` 在系统中是一个特殊的设备文件，当读它的时候，它会提供无限的空字符，不断的消耗 `CPU` 资源
默认 `CPU shares` 的值为 `1024`，如果设置 `2048` 之后

##### 多内核
`shares` 设置只能针对单核 `CPU` 进行设置，无论 `shares` 值多大最多使用时间只能为 `100%`

### 分配 `CPU` 绝对使用时间

想要严格控制 `CPU` 资源，设置 `CPU` 使用上限，不管 `CPU` 是否繁忙
`systemctl set-property user-1000.slice CPUQuota=5%`


### 动态设置 `cgroup`

`cgroup` 相关的操作都是基于内核中的 `cgroup virtual filesystem`，使用 `cgroup` 挂载这个文件系统就行
系统默认情况下但是挂载到 `/sys/fs/cgroup` 目录下面，`service` 启动时，会将自己的 `cgroup` 挂载到这个目录下的子目录


