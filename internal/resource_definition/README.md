使用自定义资源

运行生成器生成代码
- `deepcopy-gen`
  - 为每一个结构体生成 `DeepCopyObject()` 方法，这个是实现 `runtime.Object` 接口
- `client-gen`
  - 为资源创建 `clientset`

### deepcopy-gen

##### 安装
```bash
go install k8s.io/code-generator/cmd/deepcopy-gen
```

##### 添加注解

需要添加注解生成器才能正常工作

- `// +k8s:deepcopy-gen=package`
  - 注释在包级别上
  - 要求为包的所有结构体生成 `deepcopy` 方法
  - 一般写在 `doc.go` 文件中
- `// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object`
  - 写在每种类结构体之前
  - 默认情况下生成深拷贝只有 `DeepCopy()` 和 `DeepCopyInto()`
  - 此注释生成 `DeepCopyObject()`

##### 准备文件

生成器需要一个文件，包含在生成文件开头，可以使用空文件，如果添加注释需要使用 `Go` 语言的注释

##### 生成

```bash
deepcopy-gen -v 10 --go-header-file ./header.go.txt --output-file zz_generated.deepcopy.go ./v1beta1
```

### client-gen

##### 安装

```bash
go install k8s.io/code-generator/cmd/client-gen
```

##### 注解

- `// +genclient`
  - 为一个有命名空间的资源生成 `Clientset`
- `// +genclient:nonNamespaced`
  - 为没有命名空间的资源生成 `Clientset`
- `+genclient:onlyVerbs=create,get`
  - 只生成这些动词，而不是默认生成所有
- `+genclient:skipVerbs=watch`
  - 排除这些生成其他所有
- `+genclient:noStatus`
  - 如果结构体中存在 `status` 不再生成 `updateStatus`

##### AddToScheme 函数

生成的代码依赖于定义在 `resource` 包中的 `AddToScheme` 函数，为了和惯例保持一致，需要在 `register.go` 文件中编写这个函数

##### 运行

```bash
client-gen -v 10 --go-header-file ./header.go.txt --output-dir ./generated/clientset --output-pkg=github.com/pachirode/k8s_study/internal/resource_definition/generated/clientset --clientset-name=versioned --input-base= --input github.com/pachirode/k8s_study/internal/resource_definition/v1beta1

```

- `-v 10`
  - 日志级别，数值越高，输出的日志越详细
- `--go-header-file`
  - 指定文件头，添加到生成的每个文件顶部
- `--output-dir`
  - 指定生成代码的输出目录
- `--output-pkg`
  - 生成代码包的名称
- `--clientset-name=versioned`
  - 指定生成的客户端集的名称
  - 封装 `API` 资源的访问
- `--input-base=`
  - 设置输出基本路径
  - 不设置默认使用当前工作目录作为基础路径
  - 一般留空，表示从输入路径开始
- `--input $PWD/apps/v1beta1`
  - 指定生成客户端代码的 `API` 资源目录