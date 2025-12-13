# HPA

实现自动水平伸缩，即高峰期添加 `Pod` 副本，低谷期删除

[demo](../../../config/example/vpa_hpa/deploy-cpu-hpa.yaml)

### 基于 CPU 扩容

```bash
# 查看数量
kubectl get deploy,hpa,po -o wide
NAME                               READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS              IMAGES                                    SELECTOR
deployment.apps/deploy-stress      2/2     2            2           6m2s    oldboyedu-linux-tools   jasonyin2020/oldboyedu-linux-tools:v0.1   app=stress
deployment.apps/nginx-deployment   2/2     2            2           3h31m   nginx                   nginx                                     app=nginx

NAME                                             REFERENCE                  TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/stress-hpa   Deployment/deploy-stress   cpu: 0%/95%   2         5         2          6m2s

NAME                                    READY   STATUS    RESTARTS      AGE     IP           NODE               NOMINATED NODE   READINESS GATES
pod/deploy-stress-855577f4b9-bbzcr      1/1     Running   0             6m2s    10.244.1.7   k8s-test-worker    <none>           <none>
pod/deploy-stress-855577f4b9-mzzlm      1/1     Running   0             5m47s   10.244.2.5   k8s-test-worker2   <none>           <none>
pod/nginx-deployment-6b4b9457f5-9fkg7   1/1     Running   0             3h31m   10.244.2.3   k8s-test-worker2   <none>           <none>
pod/nginx-deployment-6b4b9457f5-xjrzr   1/1     Running   0             3h31m   10.244.1.3   k8s-test-worker    <none>           <none>

# 压力测试
kubectl exec deploy-stress-855577f4b9-bbzcr -- stress --cpu 8 --io 4 --vm 2 --vm-bytes 128M --timeout 10m

# 再次查看发现扩容
kubectl get deploy,hpa,po -o wide
NAME                               READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS              IMAGES                                    SELECTOR
deployment.apps/deploy-stress      3/3     3            3           11m     oldboyedu-linux-tools   jasonyin2020/oldboyedu-linux-tools:v0.1   app=stress
deployment.apps/nginx-deployment   2/2     2            2           3h36m   nginx                   nginx                                     app=nginx

NAME                                             REFERENCE                  TARGETS        MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/stress-hpa   Deployment/deploy-stress   cpu: 83%/95%   2         5         3          11m

NAME                                    READY   STATUS    RESTARTS   AGE     IP           NODE               NOMINATED NODE   READINESS GATES
pod/deploy-stress-855577f4b9-bbzcr      1/1     Running   0          11m     10.244.1.7   k8s-test-worker    <none>           <none>
pod/deploy-stress-855577f4b9-jlpt4      1/1     Running   0          108s    10.244.2.6   k8s-test-worker2   <none>           <none>
pod/deploy-stress-855577f4b9-mzzlm      1/1     Running   0          10m     10.244.2.5   k8s-test-worker2   <none>           <none>
pod/nginx-deployment-6b4b9457f5-9fkg7   1/1     Running   0          3h36m   10.244.2.3   k8s-test-worker2   <none>           <none>
pod/nginx-deployment-6b4b9457f5-xjrzr   1/1     Running   0          3h36m   10.244.1.3   k8s-test-worker    <none>           <none>

```

### 基于内存的扩容

##### tmpfs

临时文件系统，驻留在内存中 `/dev/shm`，可以用来提高服务器性能，默认为内存大小
如果数据可以丢失，放在这个目录里面可以提高访问速度

```bash
mkdir /tmp/test
sudo mount -t tmpfs -o size=100M tmpfs /tmp/test/

df -h /tmp/test/
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           100M     0  100M   0% /tmp/test

dd if=/dev/zero of=/tmp/test/bigfile.log bs=1M count=200
dd: error writing '/tmp/test/bigfile.log': No space left on device
101+0 records in
100+0 records out
104857600 bytes (105 MB, 100 MiB) copied, 0.0887049 s, 1.2 GB/s
```

##### 使用

```bash
kubectl apply -f config/example/vpa_hpa/deploy-men-hpa.yaml 

kubectl get pods -o wide
NAME                                READY   STATUS    RESTARTS   AGE     IP           NODE               NOMINATED NODE   READINESS GATES
deploy-memory-6d45944bf-sqhbp       1/1     Running   0          3s      10.244.2.7   k8s-test-worker2   <none>           <none>

# 一段时间自动扩容
kubectl get pods -o wide 
NAME                                READY   STATUS    RESTARTS      AGE     IP            NODE               NOMINATED NODE   READINESS GATES
deploy-memory-6d45944bf-8fzss       1/1     Running   1 (51s ago)   112s    10.244.1.9    k8s-test-worker    <none>           <none>
deploy-memory-6d45944bf-c57pb       1/1     Running   1 (21s ago)   82s     10.244.1.10   k8s-test-worker    <none>           <none>
deploy-memory-6d45944bf-fsvfj       1/1     Running   0             52s     10.244.2.9    k8s-test-worker2   <none>           <none>
deploy-memory-6d45944bf-m6ptx       1/1     Running   0             52s     10.244.2.8    k8s-test-worker2   <none>           <none>
deploy-memory-6d45944bf-sqhbp       1/1     Running   2 (23s ago)   2m26s   10.244.2.7    k8s-test-worker2   <none>           <none>

```