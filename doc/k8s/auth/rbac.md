# RBAC

一种授权机制，允许管理员通过 `API` 动态配置访问策略，为集群安全提供权限控制

### 资源类型

##### Role

定义命名空间范围内的权限规则

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
  - apiGroups: [ "" ] # 空字符串表示使用 core API group
    resources: [ "pods" ]
    verbs: [ "get", "watch", "list" ]
```

##### ClusterRole

定义集群范围的权限

- 集群范围资源
    - `Node`
- 非资源端点
    - `/healthz`
- 跨命名空间资源
    - 查看所有 `Pod`

##### RoleBinding

将角色绑定到用户、用户组

可以引用 `ClusterRole` 但是仅限于同一命名空间

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-secrets
  namespace: development
subjects:
  - kind: User
    name: dave
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

##### ClusterRoleBinding

在集群范围内授权

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-secrets-global
subjects:
  - kind: Group
    name: manager
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

### 资源引用

##### 子资源

`RBAC` 支持对子资源和资源实例的权限控制，使用分隔符将主资源和日志分隔

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-and-pod-logs-reader
rules:
  - apiGroups: [ "" ]
    resources: [ "pods", "pods/log" ]
    verbs: [ "get", "list" ]
```

##### 资源名称限制

通过 `resourceNames` 字段可以限制对特定资源实例的访问，不能使用 `list`, `watch` 等动词

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: configmap-updater
rules:
  - apiGroups: [ "" ]
    resources: [ "configmaps" ]
    resourceNames: [ "my-configmap" ]
    verbs: [ "update", "get" ]
```

##### 模板

`Pod`

```yaml
rules:
  - apiGroups: [ "" ]
    resources: [ "pods" ]
    verbs: [ "get", "list", "watch" ]
```

`Deployment`

```yaml
rules:
  - apiGroups: [ "apps" ]
    resources: [ "deployments" ]
    verbs: [ "get", "list", "watch", "create", "update", "patch", "delete" ]
```

非资源端点

```yaml
rules:
  - nonResourceURLs: [ "/healthz", "/healthz/*" ]
    verbs: [ "get", "post" ]
```

### 主体

- User
- Group
- ServiceAccount
- 特殊组
    - `system:authenticated`
        - 所有已认证用户
    - `system:serviceaccounts`
        - 集群中的所有服务账号

### 默认角色和角色绑定

##### 用户角色

- `cluster-admin`
    - 绑定 `system:master`
    - 超级用户，可以控制整个集群
- `admin`
    - 命名空间管理员，可以创建角色和角色绑定
- `edit`
    - 允许读写大部分资源，不可以查看或者修改角色
- `view`
    - 只读权限，不能查看角色和 `Sercret`

##### 系统角色

- `system:kube-scheduler`
    - 调度器组权限
- `system:kube-controller-manager`
    - 控制器管理器权限
- `system:node`
    - `kubelet` 组件权限
- `system:kube-proxy`
    - `kube-proxy` 组件权限

##### 自动更新机制

`API Server` 在启动时会自动更新默认角色的权限和绑定关系
`rbac.authorization.kubernetes.io/autoupdate=false` 关闭

### 常用排查命令

```bash
# 检查用户权限
kubectl auth can-i get pods --as=jane

# 检查服务账户权限
kubectl auth can-i get secrets --as=system:serviceaccount:default:my-sa
```
