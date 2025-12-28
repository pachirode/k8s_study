# K8S 学习笔记

主要参考:

https://github.com/onexstack/kubernetes-examples

https://www.lixueduan.com/categories/kubernetes

https://www.cnblogs.com/yinzhengjie/tag/Kubernetes/default.html

https://github.com/rootsongjc/kubernetes-handbook

# 介绍

- [go 版本](doc/k8s/info/go版本.md)
- [配置分类](doc/k8s/info/config.md)
- [k8s 简述](doc/k8s/info/k8s.md)
- [k8s 项目结构](doc/k8s/info/k8s项目结构.md)
- [领导者选举](doc/k8s/info/领导者选举.md)
    - [demo](internal/leader-election)

# 部署

- [常见的部署方式](doc/k8s/install/集群部署.md)
- [kind 使用](doc/k8s/install/kind使用.md)
- [二进制安装](doc/k8s/install/二进制安装.md)
- [源码](scripts/build_k8s/README.md)
- [helm](scripts/k8s/helm)
- [nfs](scripts/k8s/volume)

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
- [Pod 创建流程](doc/k8s/pod/pod创建流程.md)

# 资源

- [Node](doc/k8s/cluster/node.md)
- [Namespace](doc/k8s/cluster/namespace.md)
- [label](doc/k8s/cluster/label.md)
- [annotation](doc/k8s/cluster/annotation.md)
- [taint](doc/k8s/cluster/taint.md)
- [gc](doc/k8s/cluster/gc.md)
- [scheduler](doc/k8s/cluster/scheduler.md)

# 控制器

- [deployment](doc/k8s/controllers/deployment.md)
    - [案例](doc/k8s/controllers/deployment-demo.md)
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

# 身份验证

- [service account](doc/k8s/auth/service-account.md)
- [rbac](doc/k8s/auth/rbac.md)
- [spiffe](doc/k8s/auth/spiffe.md)
- [spier](doc/k8s/auth/spier.md)

# 网络

- [flannel](doc/k8s/network/flannel.md)
- [calico](doc/k8s/network/calico.md)

# 存储

- [secret](doc/k8s/storage/secret.md)
- [configMap](doc/k8s/storage/configmap.md)
- [volume](doc/k8s/storage/volume.md)
- [pv](doc/k8s/storage/pv.md)
- [project volume](doc/k8s/volume/project-volume.md)
- [nfs mount demo](doc/k8s/volume/pv-mount-flow.md)

# 集群

- [多集群](doc/k8s/cluster/multi-cluste.md)
- 集群安全
    - [TLS](doc/k8s/cluster/tls.md)
    - [TLS Bootstrap](doc/k8s/cluster/tls-bootstrap.md)
    - [IP伪装](doc/k8s/cluster/ip-spoofing.md)
    - [认证授权](doc/k8s/cluster/auth.md)
    - [常用设置](doc/k8s/cluster/setting.md)
    - [kubeconfig 认证](doc/k8s/cluster/kubeconfig.md)
    - [service account](doc/k8s/cluster/service-account.md)
    - [用户授权](doc/k8s/cluster/user-auth.md)
    - [常见配置](doc/k8s/cluster/common-setting.md)
- 访问集群
    - [常见访问方式](doc/k8s/cluster/access-usage.md)
    - [kubectl](doc/k8s/cluster/access-kubectl.md)
    - [kubeconfig](doc/k8s/cluster/access-kubeconfig.md)
    - [端口](doc/k8s/cluster/access-port.md)
    - [service](doc/k8s/cluster/access-service.md)
    - [外部](doc/k8s/cluster/access-external.md)
    - [dashboard](doc/k8s/cluster/access-dashboard.md)
