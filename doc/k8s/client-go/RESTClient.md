# 获取 Pod 信息

- 创建 `Config` 对象
  - 通常从 `kubconfig` 文件中加载
  - `clientcmd.RecommendedHomeFile` 为默认文件路径 `~/.kube/config`
- 明确指定 `GroupVersion` 和 `APIPath`
- 创建 `RESTClient`
- 创建一个空 `Pod` 对象，用来接收结果

```bash
# 创建测试 pod

kubectl run test \
  --image=nginx:latest \
  --restart=Never \
  --labels="app=test"
```