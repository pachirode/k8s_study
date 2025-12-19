# Job

专门用于批处理任务，负责管理仅执行一次的任务
确保批处理任务在一个或者多个 `Pod` 成功完成，并在任务结束之后自动清理

### 场景

持续监控 `Pod` 的状态，直到指定数量的 `Pod` 成功完成

- 数据处理和分析任务
- 批量计算
- 数据库迁移
- 定期清理任务

### 配置

- `restartPolicy`
    - 仅支持 `Never` 和 `onFailure`
- `spec.completions`
    - 需要成功完成的数量
- `spec.parallelism`
    - 指定并行运行的 `Pod` 数量
- `spec.backoffLimit`
    - 指定失败重试次数
- `ttlSecondsAfterFinished`
    - 自动清理完成的 `Job`

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pi-calculation
  labels:
    app: pi-job
spec:
  completions: 3
  parallelism: 2
  backoffLimit: 4
  ttlSecondsAfterFinished: 300
  template:
    metadata:
      labels:
        app: pi-job
    spec:
      containers:
        - name: pi
          image: perl:5.34
          command: [ "perl", "-Mbignum=bpi", "-wle", "print bpi(2000)" ]
          resources:
            limits:
              cpu: 100m
              memory: 128Mi
            requests:
              cpu: 50m
              memory: 64Mi
      restartPolicy: Never
```

### 执行模式

##### 单次执行模式

使用于单个任务的简单执行

##### 并行执行模式

同时运行多个 `Pod`，直到规定个成功

##### 工作队列模式

从共享队列中获取任务，直到队列为空


