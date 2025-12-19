### CNI

只关注网络设置、连接和资源清理，便于实现和各种容器运行时集成

###### 网络配置

`CNI` 使用 `JSON` 格式的网络配置，由 `CNI` 运行时处理，并传递给各插件

```json
{
  "cniVersion": "1.1.0",
  "name": "example-network",
  "plugins": [
    {
      "type": "bridge",
      "bridge": "cni0",
      "ipam": {
        "type": "host-local",
        "subnet": "10.22.0.0/16"
      }
    }
  ]
}
```

###### 插件分类

- 接口插件
    - 在容器内创建和配置网络接口
        - `bridge`
        - `macvlan`
- 链式插件
    - 对已有接口进行修改或扩展功能
        - `portmap`
        - `bandwidth`
- `IPAM` 插件
    - 负责 `IP` 地址的分配和管理
- `Meta` 插件
    - 顺序调用多个插件
        - `flannel`
        - `multus`

###### libcni 库

供容器运行时和 `CNI` 插件交互

- 加载和解析网络配置
- 按需设置环境变量并执行插件
- 处理和缓存插件结果
