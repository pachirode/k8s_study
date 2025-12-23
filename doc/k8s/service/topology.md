# topology

拓扑感知路由是一项网络优化功能，允许客户端访问服务时根据端点的拓扑位置，优先将流量路由到与客户端位于同一节点或可用区的端点上，从而减少网络延迟并降低跨区域流量成本

启用 `TopologyAwareHints` 特性门
确保 `EndpointSlice` 控制器正常运行
`kube-proxy` 组件正常运行

### 功能

- 拓扑信息收集
    - `EndpointSlice` 控制器收集每个端点的拓扑信息
        - 节点
        - 可用区
- 提示生成
    - 控制器根据拓扑分布情况分为端点生成拓扑提示
- 智能路由
    - `kube-proxy` 根据这些提示优先选择本地端点进行流量转发

### EndpointSlice

用于替代传统 `Endpoint` 资源的新 `API`

```yaml
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: example-service
  labels:
    kubernetes.io/service-name: example-svc
    endpointslice.kubernetes.io/managed-by: endpointslice-controller.k8s.io
addressType: IPv4
ports:
  - name: http
    protocol: TCP
    port: 80
endpoints:
  - addresses:
      - "10.244.1.5"
    conditions:
      ready: true
    hostname: backend-pod-1 # Pod 标识
    nodeName: worker-node-1 # 端点所在节点名称
    zone: us-west-1a # 端点所在可用区域标识
```

### 启用拓扑感知路由

##### 启用特性门控

##### 配置文件

```yaml
apiVersion: v1
kind: Service
metadata:
  name: example-service
  annotations:
    service.kubernetes.io/topology-mode: "Auto" # 添加注解来启用该功能
spec:
  selector:
    app: backend
  ports:
    - port: 80
      targetPort: 8080
```

##### 验证

启用之后配置文件将会包含拓扑信息

```yaml
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: example-service-abc123
  labels:
    kubernetes.io/service-name: example-service
endpoints:
  - addresses:
      - "10.244.1.5"
    conditions:
      ready: true
    hostname: backend-pod-1
    nodeName: worker-node-1
    zone: us-west-1a
    hints:
      forZones:
        - name: "us-west-1a"
```

### 场景

- 多区域多部署
- 成本敏感应用
    - 减少跨区域网络流量使用
- 延迟敏感应用

### 注意

- 负载均衡
    - 会导致负载均衡分布不均
- 故障转移
    - 本地端点不可用，系统会自动回退到其他可用区域
- 监控指标

### 常见问题

1. **提示未生成**：检查 Service 注解配置和特性门控状态
2. **负载不均**：评估端点分布情况，考虑调整副本数量
3. **连接失败**：验证网络策略和防火墙规则

### 诊断命令

以下是相关的代码示例：

```bash
# 查看 EndpointSlice 详情
kubectl get endpointslices -o yaml

# 检查 Service 注解
kubectl get service <service-name> -o yaml

# 查看 kube-proxy 日志
kubectl logs -n kube-system -l k8s-app=kube-proxy
```

