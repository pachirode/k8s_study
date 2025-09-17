package kube_apiserver

type APIGroup struct {
	// 内联字段，用于包含对象的基本元数据，比如 API 版本、资源类型等信息。
	TypeMeta `json:",inline"`
	// 资源组名称
	Name string `json:"name" protobuf:"bytes,1,opt,name=name"`
	// 资源组下所支持的资源版本列表
	Versions []GroupVersionForDiscovery `json:"versions" protobuf:"bytes,2,rep,name=versions"`
	// 首选版本。当一个资源内存在多个资源版本时，Kubernetes API Server 在使用资源时，会选择一个首选版本作为当前版本
	PreferredVersion GroupVersionForDiscovery `json:"preferredVersion,omitempty" protobuf:"bytes,3,opt,           name=preferredVersion"`
	// 是一个 ServerAddressByClientCIDR 类型的切片，用于描述客户端 CIDR 到服务器地址的映射关系。
	// 这个字段是可选的，用于帮助客户端以最有效的方式访问服务器
	ServerAddressByClientCIDRs []ServerAddressByClientCIDR `json:"serverAddressByClientCIDRs,omitempty" protobuf: "bytes,4,rep,name=serverAddressByClientCIDRs"`
}

// GroupVersionForDiscovery 包含了 API 版本的信息
type GroupVersionForDiscovery struct {
	// 格式为 "group/version"，用于指定 API 的组和版本信息
	GroupVersion string `json:"groupVersion" protobuf:"bytes,1,opt,name=groupVersion"`
	// 用于指定 API 的版本，格式为 "version"。这个字段保存了版本信息，避免了客户端需要拆分 GroupVersion 字段。
	Version string `json:"version" protobuf:"bytes,2,opt,name=version"`
}
