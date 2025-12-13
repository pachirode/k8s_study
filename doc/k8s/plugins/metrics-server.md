# metrics-server

为 `k8s` 集群的提供数据监控，同时提供给 `HPA` 和 `VPA`
从 `kubelet` 组件获取监控数据

```bash
# 下载 
wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/high-availability-1.21+.yaml

kubectl apply -f config/example/mertrics/metrics-ha.yaml

kubectl get pods,svc -n kube-system  -l k8s-app=metrics-server -o wide
NAME                                 READY   STATUS    RESTARTS   AGE   IP           NODE               NOMINATED NODE   READINESS GATES
pod/metrics-server-d8d9d6d88-g8wdq   1/1     Running   0          87s   10.244.2.4   k8s-test-worker2   <none>           <none>
pod/metrics-server-d8d9d6d88-m5fk2   1/1     Running   0          87s   10.244.1.6   k8s-test-worker    <none>           <none>

NAME                     TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE   SELECTOR
service/metrics-server   ClusterIP   10.96.26.14   <none>        443/TCP   87s   k8s-app=metrics-server

kubectl top node 
NAME                     CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
k8s-test-control-plane   306m         7%       646Mi           4%
k8s-test-worker          57m          1%       260Mi           1%
k8s-test-worker2         56m          1%       228Mi           1%
```

### 查找

```bash
# 查看是不同类似的 Metrics
kubectl get --raw /apis/metrics.k8s.io/v1beta1 | python3 -m json.tool
{
    "kind": "APIResourceList",
    "apiVersion": "v1",
    "groupVersion": "metrics.k8s.io/v1beta1",
    "resources": [
        {
            "name": "nodes",
            "singularName": "",
            "namespaced": false,
            "kind": "NodeMetrics",
            "verbs": [
                "get",
                "list"
            ]
        },
        {
            "name": "pods",
            "singularName": "",
            "namespaced": true,
            "kind": "PodMetrics",
            "verbs": [
                "get",
                "list"
            ]
        }
    ]
}

# 获取 Node 相关
kubectl get nodes  -o wide
NAME                     STATUS   ROLES           AGE    VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION   CONTAINER-RUNTIME
k8s-test-control-plane   Ready    control-plane   2d1h   v1.34.0   172.18.0.2    <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-39-amd64   containerd://2.1.3
k8s-test-worker          Ready    <none>          2d1h   v1.34.0   172.18.0.3    <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-39-amd64   containerd://2.1.3
k8s-test-worker2         Ready    <none>          2d1h   v1.34.0   172.18.0.4    <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-39-amd64   containerd://2.1.3

```