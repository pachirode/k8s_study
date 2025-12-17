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

### K8S 插件

实现集群内解析域名的功能，通过调取 `service`，`endpoint` 等信息，组装成 `dns` 数据用来解析请求

插件启动时启动 `service` `endpoint` `pod` 的 `Controller`，然后复用 `client-go` 中的 `informer` 机制缓存数据
处理 `DNS` 解析请求时，根据请求数据解析 `service` `namespace` `pod` 等，然后 `client-go` 从 `Indexer` 本地缓存拿到数据组装后响应给客户端

### Pod 把请求发送给 CoreDNS

```bash
kubectl exec -it test-liveness-exec -- cat /etc/resolv.conf
search default.svc.cluster.local svc.cluster.local cluster.local localdomain # 定义了 DNS 搜索路径，系统会按照这个顺序匹配域名
nameserver 10.96.0.10 # 指定使用 DNS 服务器的 IP 地址，10.96.0.10 为默认地址
options ndots:5 # 定义一些 DNS 解析选项，ndots:5 表示在进行非全名 `DNS` 查询
```

在 `Pod` 配置中 `resolve.conf` 指定的 `nameserver` 为 `10.96.0.10`，`Pod` 中发起的所有 `DNS` 都会发送到这个 `IP`
`search` 实际上就是搜索 `Service` 的 `DNS`

```bash
# 查看 DNS 配置
kubectl -n kube-system get svc kube-dns
NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   6d
```

### 配置来源

##### dnsPolicy

`Pod` 中可以指定一个 `dnsPolicy` 字段，用于配置 `Pod` 里的 `DNS` 策略

##### dnsConfig

[demo](../../../config/example/service/dns/dns-config.yaml)

### /etc/resolv.conf

`Pod` 下面该路径保存着存储 `dns` 的文件