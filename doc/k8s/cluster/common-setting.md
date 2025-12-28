# 安全管理

### 网络端口安全管理

- 只开放必要端口
- 禁用废弃的 `10255` 只读端口
- 敏感端口使用 `TLS` 加密通讯

##### 常用端口

- `6443/TCP`
    - `kube-apiserver` 限制访问源
- `10250/TCP`
    - `kubelet` 启用验证
- `10255/TCP`
    - `kubelet` 禁用
- `10256/TCP`
    - `kube-proxy` 内网访问
- `4194/TCP`
    - `kubelet` 限制访问
- `9099/TCP`
    - `calico-felix` 内网

### API 安全

##### 身份验证和授权

```bash
# 启用 RBAC
--authorization-mode=Node,RBAC
# 禁用匿名
--anonymous-auth=false
# 启用准入控制器
--enable-admission-plugins=NodeRestriction,ResourceQuota,LimitRanger
```

##### TLS 和 证书

- 启用 `TLS` 加密
- 定期轮换证书

### 节点安全

##### Kubelet

```yaml
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
authorization:
  mode: Webhook
```

##### 容器运行时

- 使用非特权容器运行工作负载
- 配置 `PSS` 替代已废弃的 `PSP`
- 启用容器镜像签名验证，确保镜像来源可信

### 安全扫描和审计

- `kube-bench`
- `Falco`

### 网络安全策略

##### Network Policy

进行了流量控制

##### 服务网格安全

### 日志和审计

##### 启用审计概念

```text
--audit-log-path=/var/log/audit.log
--audit-policy-file=/etc/kubernetes/policies/audit-policy.yaml
```

### 安全事件监控
