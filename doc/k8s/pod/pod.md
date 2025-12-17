# Pod

`Pod` 只是一个逻辑概念，用来描述一组共享某些资源的容器，类似虚拟机
主要有调度，网络，存储以及安全等相关设置

### 标签和标签选择器

[demo](../../../config/example/pod-demo/pod-label.yaml)

```bash
kubectl get pods -o wide --show-labels
NAME       READY   STATUS    RESTARTS   AGE   IP           NODE               NOMINATED NODE   READINESS GATES   LABELS
pod-demo   2/2     Running   0          72s   10.244.1.2   k8s-test-worker2   <none>           <none>            app=pod-demo,rel=stable

# 动态添加标签
```

### 配置文件解析

[demo](../../../config/example/pod-demo/pod.yaml)

- `NodeSelector`
    - 将 `Pod` 和 `Node` 进行绑定
- `NodeName`
    - `Pod` 具体调度到的节点
        - 一旦被赋予值就会被认为调度过了，一般是由调度器来设置
        - 一般测试或者调试时使用
- `HostAliases`
    - `/etc/hosts`

如果想要让容器共享宿主机的某个命名空间，必须在 `Pod` 上设置

### 生命周期

一个 `Pod` 在生命周期只会调度一次，被分配到一个节点会一值在这个节点运行

- 其实阶段为 `Pending`
    - 对象已经被创建并保存到 `etcd` 中
- 至少有一个容器正常启动，进入 `Running`
    - `Pod` 已经成功调度，至少一个容器正常运行
- 判断后续容器启动情况，进入 `Succeeded` 或者 `Failed`
- `Unknown` 异常状态
    - 可能是组从节点通讯出现问题

### 容器探针

##### 健康检查

容器中插入一个健康检查的探针，根据这个探针的返回值决定容器的状态

[案例](../../../config/example/pod-demo/container-alive.yaml)

```bash
kubectl describe pod test-liveness-exec | grep Liveness
    Liveness:       exec [cat /tmp/healthy] delay=5s timeout=1s period=5s #success=1 #failure=3
```

### 恢复机制

`Pod` 中 `Spec pod.spec.restartPolicy`，默认值为 `Always`，任何时候这个容器发生异常，它一定会被重新创建
重新创建的过程发生在当前节点上，不会跑到其他节点

- `Always`
- `OnFailure`
- `Never`

### PodPreset

一种 `API` 资源，创建 `Pod` 时，注入其他运行需要的信息，可以看作 `Pod` 模板

- `secrets`
- `volume mounts`
- `environment`

通过 `matchLabels:role: frontend` 匹配到对应的 `Pod`，把对象预定义字段添加进去
定义的字段只会在对象创建之前追加，不影响已经创建的对象
[案例](../../../config/example/pod-demo/podPerset.yaml)
[pod](../../../config/example/pod-demo/podPerset-pod.yaml)

### 终止

- 删除用户 `Pod`
- `Pod` 进入 `Terminating`
    - 移除 `endpoint`
    - 发送 `SIGTERM` 信号
    - 超出时间的使用 `SIGKILL`

### 共享

##### Network Namespace

`docker run --net=B --volumes-from=B --name=A image-A`，`docker` 实现共享网络命名空间

容器 `A` 需要依赖容器 `B` 启动，这会导致容器之间不是对等的关系

`Pod` 使用了中间容器 `Infra`，这个容器总是第一个被创建的，其他用户定义的容器则是通过 `Join Network Namespace` 方式关联进来

> `Infra` 容器使用了一个特殊的镜像，`k8s.gcr.io/pause`，该镜像始终处于停止状态

##### Volume

### 容器设置模式

`Pod` 要求我们考虑，用户在一个容器中跑多个功能不相关的应用时，是否应该成为一个 `Pod` 里面的多个容器

`sidecar` 模式，在一个 `Pod` 中，启动一个辅助容器，用来完成主容器之外的工作

##### Java Web

使用两个容器，一个容器运行 `Tomcat` 一个容器部署 `War` 包，将两个容器挂载同一个目录
[参考](../../../config/example/pod-demo/java-web.yaml)

`Init Container` 类型容器会在 `spec.containers` 定义的用户容器之前启动，知道他们依次启动并退出，用户容器才会启动

##### 日志收集

一个容器写日志，一个容器读日志并转发