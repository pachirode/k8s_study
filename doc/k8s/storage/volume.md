# Volume

容器环境下，文件默认存储在临时磁盘，引入卷
卷本质上是一个目录，可能包含数据，`Pod` 内的容器可以访问

### 常用卷

##### emptyDir

`Pod` 分配到节点时创建，`Pod` 运行期间一直存在，所有容器可以读写该卷，`Pod` 删除，卷数据也删除

容器崩溃不会导致 `emptyDir` 数据丢失，只有 `Pod` 被移除才会被清空

##### configMap 和 secret

##### pvc

##### hostPath

将主机节点的文件或者目录挂载到 `Pod`

##### nfs

支持将 `NFS` 共享挂载到 `Pod`，实现多 `Pod` 共享数据，`NFS` 卷内容不会因 `Pod` 删除而丢失
需要先搭建 `NFS` 服务器

##### csi

### subPath

指定挂载卷的子路径

### 动态子路径

`subPathExpr` 字段结合环境变量动态生成子路径

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-dynamic-subpath
spec:
  containers:
    - name: test-container
      image: nginx:1.20
      env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
      volumeMounts:
        - mountPath: /data
          name: storage-volume
          subPathExpr: $(POD_NAME)
  volumes:
    - name: storage-volume
      persistentVolumeClaim:
        claimName: my-storage
```

### projected 卷

可以将多种卷源合并挂载到同一个目录，便于统一管理

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: projected-pod
spec:
  containers:
    - name: test-container
      image: busybox:1.35
      volumeMounts:
        - name: all-in-one
          mountPath: "/projected-volume"
          readOnly: true
  volumes:
    - name: all-in-one
      projected:
        sources:
          - secret:
              name: mysecret
              items:
                - key: username
                  path: my-group/my-username
          - downwardAPI:
              items:
                - path: "labels"
                  fieldRef:
                    fieldPath: metadata.labels
          - configMap:
              name: myconfigmap
              items:
                - key: config
                  path: my-group/my-config
```

### 挂载传播

挂载传播允许容器间或 `Pod` 间共享挂载的卷

### 资源限制
