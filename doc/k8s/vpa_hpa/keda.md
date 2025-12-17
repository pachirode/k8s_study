# KEDA

基于事件驱动对 `K8S` 资源对象扩缩容的组件，用来增强 `HPA`，解决无法基于灵活事件源进行伸缩的问题

### 安装

```bash
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm install keda kedacore/keda --namespace keda --create-namespace
```

### 卸载

```bash
kubectl delete $(kubectl get scaledobjects.keda.sh,scaledjobs.keda.sh -A \
  -o jsonpath='{"-n "}{.items[*].metadata.namespace}{" "}{.items[*].kind}{"/"}{.items[*].metadata.name}{"\n"}')
helm uninstall keda -n keda
```

### 测试

```bash
kubectl apply -f config/example/mertrics/metrics-ha.yaml

```