最早期没有采用 `Go` 模块，而是使用 `dep` 等第三方工具来管理依赖，1.14 版本之后逐步迁移到 `Go` 模块系统

### 模块更新策略

- 目标版本提供新功能
- 目标版本中新 `API` 或者 `API` 变更，可以显著的改善代码质量
    - 函数
- 影响到代码修复
- 目标版本含有安全类修复
- 性能有明显提高

### 更新依赖

使用 `go.mod` 文件来管理

- `require`
    - 指定依赖版本首选项
- `replace`
    - 固定特定版本

##### 添加想要的依赖

```bash
# 添加版本到 go.mod
hack/pin-dependency.sh example.com/go/frob v1.0.4
```

该脚本封装了 `go mod edit -require` 和 `go mod edit -replace`，还有一些其他的事情

- 检查 `Go` 编译环境
- 检查 `jq` 工具是否安装，会用到该工具判断 `go mod download` 命令返回的 `JSON` 格式串
- 检查添加 `Go` 依赖包的格式是否正确，不正确会给出提示
- `go mod download` 命令下载依赖包，并检查依赖包是否下载成功
- `go mod edit -replace` 和 `go mod edit -require` 命令来添加或者更新依赖包

##### 重建 `vendor` 目录，更新所有暂存库的 `go.mod` 文件

该命令也会删除不需要的依赖包

```bash
hack/update-vendor.sh
```

##### 检查新的依赖是否为需要的版本

```bash
# 对比当前分支和 `master`
hack/lint-dependencies.sh
```

检查是否添加任何新的 `replace` 指令到 `staging` 目录中组件的 `go.mod` 文件中


