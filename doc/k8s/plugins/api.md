# API

### Extended APIServer（CRD）

允许用户自定义新的 `API` 资源类型

[CRD-resource-demo](config/crd/crd-demo.yaml)
[CRD-demo](config/crd/my_crd.yaml)

> 定义文件中 `-` 不能混用，其标识这个是一个数组元素，如果不添加会被识别为字符串

```bash
# 安装 /apis/stable.example.com/v1/namespaces/*/crontabs/... 路由
kubectl apply -f crd-demo.yaml
kubectl apply -f my-crd.yaml

kubectl get crontab
```

### Aggregated APIServer（聚合 API 服务器）

将多个 `API` 服务器聚合到 `k8s` 主服务器中，通过这种方式，用户可以将外部 `RESTful API` 作为 `k8s API` 的一部分进行访问和管理
用户在 `k8s` 中统一管理不同的服务和资源，并复用 `k8s` 提供的各种能力

[自定义服务](config/api/api_custom_service.yaml)
[k8s服务](config/api/k8s_resource_service.yaml)

```bash
kubectl apply -f api_custom_service.yaml
kubectl apply -f k8s_resource_service.yaml

# 检查状态
kubectl get pods -l app=custom-resource -n default
kubectl get svc custom-resource-service -n default
kubectl get apiservices v1.example.com

# 将服务暴露的 80 端口映射到本地 8080 端口
kubectl port-forward svc/custom-resource-service 8080:80
curl http://localhost:8080/apis/example.com/v1

kubectl get --raw /apis/example.com/v1/custom
```

### External Metrics

`k8s` 集群内置的一些常用的监控指标，`HPA` 根据这些指标来扩缩容 `Pod`
允许用户自定义自己的指标，并设置扩缩容

##### 流程

- 指标收集
    - 外部系统 `Prometheus`
- 指标 `API`
    - 通过 `Metrics API` 访问外部指标，用户需要实现一个 `Metrics Adapter`，将外部格式转换为内部格式
- `HPA` 调整
    - 根据外部指标的值来决定增加还是减少 `Pod`

### Webhook

允许通过 `HTTP` 请求的方式调用外部服务，通过这些外部服务扩展 `k8s` 的能力

- `Authorization Webhook`
  - `API` 请求之前，决定请求是否被允许
- `Authentication Webhook`
  - 验证用户身份，可以调用外部系统
- `Admission Webhook`
  - `Mutating Webhook`
    - 资源创建和更新之前，可以修改请求对象
    - 资源被保存之前可以被修改
  - `Validating Webhook`
    - 资源创建和更新前，验证对象是否合法

##### 流程

- 客户端请求 `k8s`，`k8s` 发现涉及配置的 `Webhook`
- 根据配置的请求地址，请求路径等信息，发送 `HTTP` 请求