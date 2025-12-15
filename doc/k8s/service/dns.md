# CoreDNS

集群搭建完成会存在两个 `coredns` 的 `Pod`，配置文件来源于 `ConfigMap`

```bash
kubectl -n kube-system get pod | grep coredns
coredns-66bc5c9577-f29bm                         1/1     Running   1 (3d4h ago)   5d2h
coredns-66bc5c9577-hjqkp                         1/1     Running   1 (3d4h ago)   5d2h

kubectl get configmaps -n kube-system
NAME                                                   DATA   AGE
coredns                                                1      5d2h
```

[配置](../../../config/example/service/dns/configmap-dns.yaml)

`data.Corefile` 字段就是 `CoreDNS` 的配置文件

- `.:53` 表示在 `53` 端口监听服务，`.` 表示任意的域名都是由该服务负责
    - 可以启动多个服务，使用域名来区分，`a.com:53` `b.com:53`
- 后续内容为启动的插件
    - 最重要的为 `Kubernetes` 插件，实现了 `kubeDNS` 功能