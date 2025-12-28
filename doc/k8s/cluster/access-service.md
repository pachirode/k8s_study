# 使用 Service

`Service` 会自动在多个 `Pod` 之间分发请求

```bash
# 创建 Deployment
kubectl create deployment hello-world --image=asbubam/hello-node:latest --port=8080
# 扩展副本
kubectl scale deployment hello-world --replicas=2
# 添加标签
kubectl label deployment hello-world run=load-balancer-example

# 创建 NodePort 类型的 Service
kubectl expose deployment hello-world --type=NodePort --name=example-service
# 查看 service 详情
kubectl describe services example-service
# 查看详细信息
kubectl get pods -l app=hello-world -o wide

# 获取节点 IP 地址
kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}'

kubectl get nodes -o wide
NAME                     STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION   CONTAINER-RUNTIME
k8s-test-control-plane   Ready    control-plane   9d    v1.34.0   172.18.0.2    <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-39-amd64   containerd://2.1.3
k8s-test-worker          Ready    <none>          9d    v1.34.0   172.18.0.3    <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-39-amd64   containerd://2.1.3
k8s-test-worker2         Ready    <none>          9d    v1.34.0   172.18.0.4    <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-39-amd64   containerd://2.1.3

curl http://<node-ip>:<node-port>
curl http://172.18.0.3:31737
Hello World!
```
