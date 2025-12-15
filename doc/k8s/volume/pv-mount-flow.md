# PVC 存储

### 构建 `NFS` 网络文件系统

[脚本](../../../scripts/k8s/volume/install-nfs-server.sh)

### k8s 集群安装 nfs 客户端驱动

[脚本](../../../scripts/k8s/volume/install-nfs-client.sh)

### 创建 `PV`

[pv](../../../config/example/volume/demo/pv.yaml)

[pvc](../../../config/example/volume/demo/pvc.yaml)

### 验证

[redis-demo](../../../config/example/volume/demo/redis.yaml)

```bash
kubectl get pvc
NAME         STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
redis-data   Bound     pv-nfs   5Gi        RWO,ROX,RWX    nfs-sc         <unset>                 14m

kubectl exec -it redis-demo  -- /bin/sh
# redis-cli 
127.0.0.1:6379> SET test test
OK
BGSAVE

# 删除 Pod 之后查看数据是否丢失
kubectl delete -f config/example/volume/demo/redis.yaml 

ls /tmp/nfs/data/
dump.rdb
```

### 删除 PVC

当有 `Pod` 在使用 `PVC` 时，我们无法手动删除 `PVC`
`PVC` 的状态会变为 `Terminating`，直到所有使用该 `PVC` 的 `Pod` 都被移除，才会被真正删除