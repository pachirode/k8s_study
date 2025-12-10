# Service 无法通过 DNS 访问

进入一个 `Pod` 中，查看 `Master` 节点的 `Service DNS` 状态

```bash
nslookup kubernetes.default
Server:         10.96.0.10
Address:        10.96.0.10:53
```

无法获取信息，需要检查 `kube-dns` 运行状态和日志

# Service 无法通过 ClusterIP 访问

查看服务是否由 `Endpoints`

```bash
kubectl get endpoints <service_name>
```

如果正常，需要确定 `kube-proxy` 运行状态

```bash
kubectl logs <kube-proxy-pod-name>
```

如果正常需要查看宿主机 `iptables` 设置

- 入口链规则是否和 `VIP` 和 `Service` 端口对应
- `DNAT` 和 `Endpoints` 对应
- 负载均衡链数量和 `Endpoints` 数量
- `NodePort`，`POSTROUTING` 处的 `SNAT` 链