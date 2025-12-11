# Projected Volume

特殊的 `volume`，存在的目的不是为了存放在容器里面的数据，主要是为了容器提供预定义好的数据

- `ConfigMap`
    - 保存配置数据的键值对，可以保存单个属性或者配置文件
- `Secret`
    - 为 `Pod` 提供密码，`Token` 等敏感数据
- `Downward API`
    - 让 `Pod` 里的容器能给直接获取这个 `Pod API` 对象本身的信息
    - 只能获取容器启动之前就确认的信息
- `ServiceAccountToken`
    - 一种特殊的 `Secret`，`k8s` 系统内置的权限分布

### ConfigMap

##### 创建

参数

- `–from-file`
    - 单个文件
    - 文件夹
- `–from-literal`
    - 对应一条条目信息，相当于配置文件中的 `data`
- `–from-env-file`

[配置](../../../config/example/projected-volume/configmap.yaml)

```bash
kubectl apply -f config/example/projected-volume/configmap.yaml

kubectl get configmap test-configmap 
NAME             DATA   AGE
test-configmap   1      21s
```

##### 使用

`ConfigMap` 必须在 `Pod` 使用之前创建
使用 `envFrom`，会自动忽略掉无效的键
`Pod` 只能使用同一个命名空间的

- 将 `ConfigMap` 中的数据设置为环境变量
- 使用 `Volume` 将其作为文件挂载或者目录挂载
    - 其中的每一个 `key` 都会挂载为一个单独文件

环境变量

```bash
kubectl apply -f config/example/projected-volume/busybox-test.yaml

kubectl logs test-pod | grep TEST
CUSTOM_TEST=test-configmap
```

挂载

```bash
kubectl apply -f config/example/projected-volume/busybox-test-mount.yaml

kubectl exec -it test-pod -- sh
/ # cd /etc/foo/
/etc/foo # ls
name  test

```

### Secret

三种类型

- `Opaque`
    - `base64` 编码格式，可以直接解码，加密行弱
- `Service Account`
    - 访问 `k8s API`，系统自动创建，挂载到 `Pod` `/run/secrets/kubernetes.io/serviceaccount`
- `kubernetes.io/dockerconfigjson`
    - 存储私有 `docker registry` 认证信息

```bash
kubectl apply -f config/example/projected-volume/secret.yaml

kubectl get secrets
NAME          TYPE     DATA   AGE
test-secret   Opaque   1      2s

#  describe 或者 get 命令不会直接显示 secret 中的内容
kubectl get secret test-secret -o go-template='{{.data}}'
map[test:c2VjcmV0LXRlc3Q=](base)
```

##### 使用

环境变量

```bash
kubectl apply -f config/example/projected-volume/busybox-secret-test.yaml

kubectl logs test-pod | grep HELLO
CUSTOM_HELLO=secret-test
```

挂载

```bash
kubectl exec -it test-pod -- sh
/ # ls /etc/foo/
test
/ # cat /etc/foo/test
secret-test/
```

### Downward API

[配置](../../../config/example/projected-volume/busybox-downward.yaml)