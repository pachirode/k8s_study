# CronJob

让 `k8s` 能够原生的支持定时任务编排，实现自动化运维、数据备份等周期性作业

### 场景

- 指定时间点运行一次性任务
- 创建周期性运行的任务
    - 数据库备份，发送邮件

### 配置文件

- `spec.schedule`
    - 调度配置，指定任务运行周期
- `spec.jobTemplate`
    - 指定需要运行的任务，`Job` 模板

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: hello
              image: busybox:1.35
              args:
                - /bin/sh
                - -c
                - date; echo Hello from the Kubernetes cluster
          restartPolicy: OnFailure
```

### 注意事项

##### 调度可靠性

某些情况下调度会创建多个 `Job` 对象，所以操作需要设计为幂等

##### 时区

如果控制平面在不同的时区的多个节点上运行，调度事件可能会不可预测

##### Job 管理

`Job` 负责重试创建 `Pod`，并决定 `Pod` 组成功还是失败
`CronJob` 不会检查 `Pod` 的状态

##### 删除 CronJob

删除 `CronJob` 资源不会自动删除其创建的 `Job` 和 `Pod`，需要手动清理相关资源

