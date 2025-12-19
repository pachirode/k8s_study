# Label

到 `k8s` 上的键值对标签，可以创建对象指定，也可以后续修改
`k8s` 会为 `Label` 建立索引和反向索引，以优化查询和监听操作

### 标签选择器

根据标签筛选对象集合，是 `k8s` 资源编排的核心能力

##### 等值选择器

通过 `=`、`==`、`!=` 来筛选对象，常用于 `Service` `ReplicationController`

```bash
kubectl get pods -l environment=production,tier=frontend
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: nginx
    environment: production
  ports:
    - port: 80
```

##### 集合选择器

集合选择器通过 `in`、`notin`、`exists` 操作符实现更加复杂的筛选逻辑
在 `Deployment`、`ReplicaSet`、`DaemonSet`、`Job`，支持复杂的 `matchLables` 和 `matchExpressions`

```bash
kubectl get pods -l 'environment in (production,qa)'
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
    matchExpressions:
      - key: tier
        operator: In
        values: [ frontend, backend ]
      - key: environment
        operator: NotIn
        values: [ development ]
      - key: version
        operator: Exists
```

##### 节点和 Pod 亲和性

标签选择器可用于节点亲和性场景，实现灵活的调度约束

```yaml
apiVersion: v1
kind: Pod
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: kubernetes.io/arch
                operator: In
                values: [ amd64, arm64 ]
              - key: node-type
                operator: NotIn
                values: [ spot ]
    podAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchLabels:
                app: cache
            topologyKey: kubernetes.io/hostname
```

