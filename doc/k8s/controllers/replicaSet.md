# ReplicationController 和 ReplicaSet

管理 `Pod` 副本的控制器，确保指定数量的 `Pod` 副本始终在集群中运行

### ReplicationController

早期版本中管理 `Pod` 副本的控制器

### ReplicaSet

新版副本控制器，标签选择器进行增强
可以独立使用，但是一般由 `Deployment` 来自动管理
