# admission

准入控制器，实现策略治理和安全合规的关键机制，通过内建插件和 `webhook` 扩展，实现自动化、安全控制

### 功能

请求从 `kubectl` 或客户端发出之后，会经过验证和鉴权阶段，让后进入准入控制
准入控制是一组可插拔的拦截器，在请求到达 `etcd` 之前执行吗，是修改和验证资源的最后关口

- 验证请求是否合法
- 自动修改请求
- 实施安全策略
- 触发外部逻辑
    - 准入 `webhook`

### 准入控制器类型

- `MutatingAdmissionController`
    - 可修改请求对象
        - 为 `Pod` 自动注入默认字段
- `ValidatingAdmissionController`
    - 仅验证请求是否合法，拒绝不符合安全策略的 `Pod`

##### 内置准入控制器插件

- `NamespaceLifecycle`
    - 防止删除系统命名空间或者删除中的命名空间创建对象
- `LimitRanger`
    - 根据 `LimitRange` 为 `Pod` 设置默认资源
- `ServiceAccount`
    - 为 `Pod` 分配 `ServiceAccount`
- `ResourceQuota`
    - 检查命名空间配额是否超限
- `NodeRestriction`
    - 限制 `kubelet` 对 `Node/Pod` 对象的修改权限

```bash
# 启用部分准入控制器插件
kube-apiserver \
  --enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota,PodSecurity

# 禁用指定插件
--disable-admission-plugins=PodSecurity
```

##### 扩展准入组件

通过 `Adminssion Webhook` 实现可扩展准入控制

### 使用场景

- 安全策略控制
    - 结合 `PodSecurity` 和 `Webhook`，禁止特定镜像仓库的容器运行
- 自动化默认值注入
    - 为 `Pod` 自动注入 `Sidecar` 容器，为 `Job` 添加调度策略
- 资源管理和审计
    - 拒绝未打标签的资源。记录变更日志或审计请求
