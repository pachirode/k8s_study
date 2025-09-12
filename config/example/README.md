# CPU 配置文件

通常情况下一个 `CPU` 资源配额相当大，所以 `K8S` 里通常使用千分之一作为最小单位，使用 `m` 表示
通常一个容器的 `CPU` 配置为 `100~300m`

```yaml
spec:
  containers:
    - name: db
      image: mysql
      resources:
        requests: # 通常被设置为一个较小的值，表示容器平时工作负载下的资源需求
          memory: "64Mi"
          cpu: "250m"
        limits: # 峰值负载情况下资源占用的最大值
          memory: "128Mi"
          cpu: "500m"
```

# 标签选择

```yaml
# 筛选 app=xxx
selector:
  app: xxx
```

```yaml
# 筛选 app=xxx, 且 key=XXX 并且值在列表中
selector:
  matchLabels:
    app: xxx
  matchExpressions:
    - { key: XXX, operator: In, values: [ xxx, XXX ] }
    # 或使用以下写法
    - key: XXX
      operator: In # In, NotIn, Exists and DoesNotExist
      values: [ xxx, XXX ]
```

# 卷

```yaml
template:
  metadata:
    labels:
      app: myapp
    spec:
      volumes:
        - name: datavol # 声明一个卷
          emptyDir: { }
      containers:
        - name: nginx
          image: nginx
          volumeMounts:
            - mountPath: /mydata # 容器中引用改卷
              name: datavol
```

# 持久卷

### 声明持久卷

```yaml
# 声明了一个 NFS 类型的 PV
apiVersion: v1
kind: PersistentVolume
metadata:
  name:pv0001
spec:
  capacity:
    storage: 8Gi
  accessModes:
    - ReadWriteOnce
  nfs:
    path: /somepath
    server: 192.168.0.106
```

`accessModes`

- `ReadWriteOnce`
    - 读写权限，只允许被单个 `Node` 挂载
- `ReadOnlyMany`
    - 只读权限，允许被多个 `Node` 挂载
- `ReadWriteMany`
    - 读写权限，允许被多个 `Node` 挂载

### 申请持久卷

某个 `Pod` 需要使用某种类型的 `PV`，需要事先定义 `PVC`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myclaim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 8Gi
```

### 引用持久卷

```yaml
volumes:
  - name: mypd
    persistentVolumeClaim:
      claimName: myclaim
```