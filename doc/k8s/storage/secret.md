# `Secret`

用于保存少量敏感信息

### 使用方式

- 作为 `volume` 挂载为文件
- 作为环境变量挂载给容器
- 作为镜像拉取凭据 `imagePullSecrets`

> 以点号开头的文件可以设置为隐藏

### 数据类型

- `Opaque`
    - 用户自定义数据
- `kubernetes.io/service-account-token`
    - `Service Account` 的认证令牌
- `kubernetes.io/dockerconfigjson`
    - `Docker registry` 认证信息
- `kubernetes.io/tls`
    - `TLS` 证书和私钥
- `kubernetes.io/basic-auth`
    - 基本认证凭据

##### Opaque

最常用的 `Secret` 类似，用于存储任意的敏感数据，数据必须使用 `base64` 编码

### 内置 secret

##### ServiceAccount 自动创建 API 凭证 Secret

`k8s` 会为每个 `ServiceAccount` 自动创建访问 `API` 的 `Secret`，并自动挂载到 `Pod`

### 生命周期

- 仅在被 `Pod` 消费时分发到节点
- 文件被存储在 `tmpfs`，不落盘
- `Pod` 删除之后，文件自动清理

### 案例

##### SSH 密钥

```bash
kubectl create secret generic ssh-key-secret \
  --from-file=ssh-privatekey=/path/to/.ssh/id_rsa \
  --from-file=ssh-publickey=/path/to/.ssh/id_rsa.pub
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-test-pod
spec:
  volumes:
    - name: secret-volume
      secret:
        secretName: ssh-key-secret
  containers:
    - name: ssh-test-container
      image: mySshImage
      volumeMounts:
        - name: secret-volume
          readOnly: true
          mountPath: "/etc/secret-volume"
```
