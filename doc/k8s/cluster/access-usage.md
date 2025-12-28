# 访问集群

### 创建 URL

- 集群级资源
    - `/apis/GROUP/VERSION/RESOURCETYPE`
- 命名空间级资源
    - `/apis/GROUP/VERSION/namespaces/NAMESPACE/RESOURCETYPE`
- 单个资源
    - `/apis/GROUP/VERSION/namespaces/NAMESPACE/RESOURCETYPE/NAME`

### kubectl 原理

作为 `k8s API` 客户端，将用户命令转换为 `HTTP` 请求
`kubeconfig` 包含集群信息，认证方式，通过 `kubeconfig` 文件自动完成 `API Server` 认证

##### 输出格式

支持多种输出格式，方便脚本化处理

```bash
-o 格式
```

- `json`
- `yaml`
- `wide`
    - 额外信息
- `name`
- `custom-columns`
    - 自定义列格式
- `jsonpath`
    - `JSONPath` 过滤，提取特定字段
- `go-template`

### 直接访问 API

通过 `kubectl proxy` 启动本地代理，直接访问 `API`

```bash
kubectl proxy --port=8080
curl http://localhost:8080/api/v1/namespaces/default/pods
```

### Server-Side Apply

更新资源通常是通过客户端命令，计算出需要的变更并提交给 `API` 服务器
`server-side` 计算变更在服务器上进行，可以避免多个客户端修改的冲突

支持多用户或控制器协同管理同一对象，自动跟踪字段归属，避免互相覆盖

- 字段管理跟踪每个字段的归属
- 不同管理者设置同一个字段会有冲突
- 可以强制覆盖他人字段

### 其他访问方式

其他语言可以通过第三库访问

### API 代理和端口转发

- 使用 `kubectl proxy` 创建本地代理
- 直接带认证访问 `API Server`
- 通过端口转发访问特定服务
