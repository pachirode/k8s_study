# 通过端口转发访问集群中应用

- 端口转发会增加网络延迟
- 生产环境避免使用，不够安全，考虑 `Service` 或 `Ingress`

### 案例

- 部署一个 `Redis Pod`
- 将本地端口转发到 `Pod` 端口

```bash
# 本地端口转发，只能本地访问
kubectl port-forward pod/redis-server 6379:6379

# 可以绑定到所有网络接口
kubectl port-forward --address 0.0.0.0 pod/redis-server 6379:6379

# 后台运行
kubectl port-forward pod/redis-server 6379:6379 &
```
