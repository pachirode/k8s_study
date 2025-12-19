# StatefulSet

专门用来管理有状态应用的控制器，为 `Pod` 提供唯一标识，并保证部署和扩缩容有序性

### 应用场景

适合需要稳定标识符或者有序部署的应用

- 稳定持久化存储
    - `Pod` 重新调度之后访问相同的持久化数据，基于 `PVC`
- 稳定的网络标识
    - `Pod` 重新调度之后 `PodName` 和 `HostName` 保持不变，基于 `Headless Service`
- 有序部署和扩展
    - `Pod` 按照定义顺序依次部署，前面的完成才能运行下面的
- 有序收缩和删除
- 有序滚动更新

### 核心组件

- `Headless Service`
    - 定义网络 `DNS`
- `volumeClaimTemplates`
    - 创建 `PV`
- `StatefulSet`
    - 定义具体应用配置

##### DNS 命名规范

`StatefulSet` 中的每个 `Pod` 的 `DNS`
`<statefulSetName>-<ordinal>.<serviceName>.<namespace>.svc.cluster.local`
> ordinal:   pod 序号从 0 开始

### 使用限制

- `Pod` 的存储必须由 `PV Provisioner` 根据 `storage class` 配置或者管理员预先配置
- 删除或缩容不会删除关联存储卷，需要手动删除
- `Headless Service` 来关联 `Pod` 网络
- 不建议将 `pod.Spec.TerminationGracePeriodSeconds` 设置为 0

### Pod 管理

通过序数和 `DNS` 规则为每个 `Pod` 提供唯一身份，便于服务发现和数据隔离

##### 管理策略

- `OderedReady`
    - 默认，按照顺序启动和终止 `Pod`
- `Parallel`
    - 并行启动和终止所有 `Pod`

##### 更新策略

- `OnDelete`
    - 手动删除之后会创建新版的 `Pod`
- `RollingUpdate`
    - 推荐，自动滚动更新，有序从大到小更新
    - 可以单独设置分区更新

```yaml
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 0
```

### 外部访问

需要从集群外访问特定的 `Pod`

##### NodePort Service

```bash
# 为特定 Pod 添加标签
kubectl label pod zk-0 instance=zk-0
kubectl label pod zk-1 instance=zk-1

# 暴露为 NodePort 服务
kubectl expose pod zk-0 --port=2181 --target-port=2181 \
  --name=zk-0-external --selector=instance=zk-0 --type=NodePort

kubectl expose pod zk-1 --port=2181 --target-port=2181 \
  --name=zk-1-external --selector=instance=zk-1 --type=NodePort
```

##### LoadBalancer Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: zk-0-lb
spec:
  type: LoadBalancer
  ports:
    - port: 2181
      targetPort: 2181
  selector:
    statefulset.kubernetes.io/pod-name: zk-0
```

### 示例

##### zookeeper

```yaml
apiVersion: v1
kind: Service
metadata:
  name: zk-headless
  labels:
    app: zookeeper
spec:
  ports:
    - port: 2888
      name: server
    - port: 3888
      name: leader-election
  clusterIP: None
  selector:
    app: zookeeper
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: zk
spec:
  serviceName: zk-headless
  replicas: 3
  selector:
    matchLabels:
      app: zookeeper
  template:
    metadata:
      labels:
        app: zookeeper
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: app
                    operator: In
                    values:
                      - zookeeper
              topologyKey: kubernetes.io/hostname
      containers:
        - name: zookeeper
          image: zookeeper:3.7
          ports:
            - containerPort: 2181
              name: client
            - containerPort: 2888
              name: server
            - containerPort: 3888
              name: leader-election
          env:
            - name: ZK_REPLICAS
              value: "3"
            - name: ZK_HEAP_SIZE
              value: "1G"
            - name: ZK_CLIENT_PORT
              value: "2181"
            - name: ZK_SERVER_PORT
              value: "2888"
            - name: ZK_ELECTION_PORT
              value: "3888"
          readinessProbe:
            exec:
              command:
                - sh
                - -c
                - "echo ruok | nc localhost 2181 | grep imok"
            initialDelaySeconds: 10
            timeoutSeconds: 5
          livenessProbe:
            exec:
              command:
                - sh
                - -c
                - "echo ruok | nc localhost 2181 | grep imok"
            initialDelaySeconds: 10
            timeoutSeconds: 5
          volumeMounts:
            - name: datadir
              mountPath: /data
      securityContext:
        runAsUser: 1000
        fsGroup: 1000
  volumeClaimTemplates:
    - metadata:
        name: datadir
      spec:
        accessModes: [ "ReadWriteOnce" ]
        storageClassName: "fast-ssd"
        resources:
          requests:
            storage: 10Gi
```
