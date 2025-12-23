# K8S 学习笔记

主要参考:

https://github.com/onexstack/kubernetes-examples

https://www.lixueduan.com/categories/kubernetes

https://www.cnblogs.com/yinzhengjie/tag/Kubernetes/default.html

https://github.com/rootsongjc/kubernetes-handbook

# 创建集群

[集群部署](doc/k8s/集群部署.md)

### [Kind](doc/k8s/kind使用.md)

# 网络

### [flannel](doc/k8s/network/flannel.md)

# Volume

[volume](doc/k8s/volume/volume.md)

[project volume](doc/k8s/volume/project-volume.md)

[nfs mount demo](doc/k8s/volume/pv-mount-flow.md)

# [kube-apiserver](doc/k8s/kube-apiserver)

# plugin

[metrics-server](doc/k8s/plugins/metrics-server.md)

# 接口

[interface](doc/k8s/interface/interface.md)

- [cri](doc/k8s/interface/cri.md)
- [csi](doc/k8s/interface/csi.md)
- [cni](doc/k8s/interface/cni.md)

# Pod

[Pod 概述](doc/k8s/pod/pod.md)

- [Pod 解析](doc/k8s/pod/detail.md)
- [Pod 常见容器](doc/k8s/pod/container.md)
- [Pod 容器探针](doc/k8s/pod/probe.md)
- [Pod Hook](doc/k8s/pod/hook.md)
- [Pod 中断](doc/k8s/pod/pdb.md)

# Cluster

- [Node](doc/k8s/cluster/node.md)
- [Namespace](doc/k8s/cluster/namespace.md)
- [label](doc/k8s/cluster/label.md)
- [annotation](doc/k8s/cluster/annotation.md)
- [taint](doc/k8s/cluster/taint.md)
- [gc](doc/k8s/cluster/gc.md)
- [scheduler](doc/k8s/cluster/scheduler.md)

# Controller

- [deployment](doc/k8s/controllers/deployment.md)
- [daemonSet](doc/k8s/controllers/daemonset.md)
- [replicaSet](doc/k8s/controllers/replicaSet.md)
- [statefulSet](doc/k8s/controllers/statefulSet.md)
- [job](doc/k8s/controllers/job.md)
- [cronJob](doc/k8s/controllers/cronJob.md)
- [hpa](doc/k8s/controllers/hpa.md)
- [vpa](doc/k8s/controllers/vpa.md)
- [keda](doc/k8s/controllers/keda.md)
- [ingress](doc/k8s/controllers/ingress.md)
- [admission](doc/k8s/controllers/admission.md)

# 服务发现和路由

- [service](doc/k8s/service/service.md)
- [ingress](doc/k8s/service/ingress.md)
- [topology](doc/k8s/service/topology.md)
- [gateway](doc/k8s/service/gateway.md)

# 故障排除

[service](doc/k8s/debug/service/service.md)

