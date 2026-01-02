# Argo Workflow

云原生工作流引擎，用于在集权上并行作业，`Argo` 作为 `CRD` 实现

- 定义工作流
    - 工作流的每一个步骤都是一个容器
- 多个步骤工作流定义为任务

### 组件

- `argo-server`
    - 为工作流提供 `API` 和 `UI` 界面
- `workflow-controller`
    - 解析用户创建的 `CR` 对象并启动 `Pod` 来真正的运行流水线

### 部署

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argo-workflows argo/argo-workflows -n argo --create-namespace --set server.authMode=server

kubectl -n argo get po
NAME                                                  READY   STATUS    RESTARTS   AGE
argo-workflows-server-6cdf988c56-nhbm4                1/1     Running   0          65s
argo-workflows-workflow-controller-6789fc848c-x5zdh   1/1     Running   0          65s

# 将 Service 切换为 NodePort
kubectl patch svc argo-workflows-server -n argo -p '{"spec": {"type": "NodePort"}}'
# 本地使用 Kind 启动集群，将服务转发出来
kubectl -n argo port-forward --address 0.0.0.0 svc/argo-workflows-server 8081:2746
```

### 测试

```bash
kubectl create -f argo-demo/hello.yaml

kubectl get workflow
NAME          STATUS    AGE   MESSAGE
steps-jxvfx   Running   10s
```

### 基本概念

- `Workflow`
    - 流水线，真正运行流水线的实例
- `WorkflowTemplate`
    - 流水线模板，可以基于模板创建流水线
- `template`
    - 一个流水线由多个模板组成，可以理解为流水线中的每一个步骤
