package kube_apiserver

// APIResource specifies the name of a resource and whether it is namespaced.
type APIResource struct {
	// 资源名称
	Name string `json:"name" protobuf:"bytes,1,opt,name=name"`
	// 资源的单数名称，它必须小写字母组成，默认使用资源类型（Kind）的小写形式命名。例如：Pod
	// 资源的单数名称为 pod，复数名称为 pods
	SingularName string `json:"singularName" protobuf:"bytes,6,opt,name=singularName"`
	// 资源是否拥有所属命名空间
	Namespaced bool `json:"namespaced" protobuf:"varint,2,opt,name=namespaced"`
	// 资源所在的资源组名称
	Group string `json:"group,omitempty" protobuf:"bytes,8,opt,name=group"`
	// 资源所在的资源版本
	Version string `json:"version,omitempty" protobuf:"bytes,9,opt,name=version"`
	// 资源类型
	Kind string `json:"kind" protobuf:"bytes,3,opt,name=kind"`
	// 资源可操作的方法列表，例如：get、list、watch、create、update、patch、delete、deletecollection 和 proxy
	Verbs Verbs `json:"verbs" protobuf:"bytes,4,opt,name=verbs"`
	// 资源的简称，例如：Pod 资源的简称为 po
	ShortNames []string `json:"shortNames,omitempty" protobuf:"bytes,5,rep,name=shortNames"`
	// 资源所属的分组列表，例如 "all"
	Categories []string `json:"categories,omitempty" protobuf:"bytes,7,rep,name=categories"`
	// 资源的存储版本的哈希值，即资源在写入数据存储时转换的版本。这是一个 alpha 特性，可能在将来发生变化或被移除。
	StorageVersionHash string `json:"storageVersionHash,omitempty" protobuf:"bytes,10,opt,name=storageVersionHash"`
}
