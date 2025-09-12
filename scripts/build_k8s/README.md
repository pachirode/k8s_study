# 使用 Docker 编译源码

```bash
sudo apt install -y docker-buildx-plugin
```

### 基本流程

使用 `build` 目录下脚本构建或者测试，其中 `Dockerfile` 文件为 [build/build-image/Dockerfile](docker/Dockerfile)
所有 `docker` 容器名都附带一个哈希值，该值是从文件路径派生而来（允许 `CI` 机器之类的环境并行使用），还有版本号，如果版本号发生改变，所有的状态都将被清除，并开始干净构建

- 首先会在 `_output/images/build-image` 目录中创建一个 `context` 目录，该目录只存放用来参与构建的文件，最小化构建镜像需要打包的文件数量
- 构建源码时，会基于 `${KUBE_CROSS_IMAGE}:${KUBE_CROSS_VERSION}` 镜像启动 3 个容器
    - `data` 容器
        - 用来存储所有数据，以支持增量构建
        - 每次运行之后保留
    - `rsync` 容器
        - 将数据从 `data` 容器中拷贝出来，或者从外面拷贝进去
        - 每次运行之后销毁
    - `build` 容器用来执行源码编译
        - 每次运行之后销毁
- 数据同步
    - 使用 `rsync` 高效的在容器和宿主机之间进行数据传输，`Docker` 选择临时端口，可以通过 `KUBE_RSYNC_PORT` 环境变量来修改此端口

### 执行构建

- 本地构建
  - `release`
    - 本地构建一个 `release`
  - `quick-release`
    - 构建一个 `release`，但是不执行测试
  - `release-skip-tests`
    - 构建一个 `release`，但是不执行单元测试
- 使用 `Docker` 容器构建规则
  - `release-in-a-container`
  - `release-images`
  - `quick-release-images`

### 构建结果

构建的 `Docker` 镜像，会以 `tar` 包的形式发布到 `_output/release-tars/amd64`
所有的构建产物都会存放在 `_output` 目录中，编译的二进制文件和归档的 `Docker` 镜像

# 源码编译

安装依赖包

### 基本编译方式

- `KUBE_BUILD_PLATFORMS=linux/amd64 make WHAT=cmd/<subsystem>`
  - `KUBE_BUILD_PLATFORMS`
    - 指定编译的 `OS` 和 `CPU` 架构
    - 如果不指定默认使用编译时所使用的架构
  - 内存较少会导致 `OOM` 错误
  - `<subsystem>`
    - 可以替换为 `cmd` 目录下任何目录文件
  - 编译出来的二进制产物存放在 `_output/bin/`，文件名就是组件名

### 编译

- 限制编译器错误数量
  - `K8S` 默认限制错误报告 10 个，`GOGCFLAGS="-e"` 用来移除这个限制
- `GOFLAGS=-v`
  - 编译参数，开启 `verbose` 日志
- `GOGCFLAGS="-N -l"`
  - 禁止编译优化和内联，减小可执行文件大小

### 测试

测试之前需要保证代码是干净的 `git status|grep 'nothing to commit, working tree clean'`

分类
- 预提交验证
  - `make verify`
  - 如果某个测试失败了，一般会有一个更新脚本来解决问题 `hack/update-*.sh`
- 单元测试
  - `make test`
- 集成测试
  - `make test-integration`
- `E2E` 测试


# 快速启动 `K8S`

环境配置
- 容器运行时
- `Etcd`
- `Go`
- `OpenSSL` 和 `CFSSL`

### 设置环境变量

```bash
export CONTAINER_RUNTIME_ENDPOINT="unix:///run/containerd/containerd.sock"
export ETCD_PORT=2479 # 此处环境变量需要重新设置 `Etcd` 的监听端口
````

### 启用 `CRI`
