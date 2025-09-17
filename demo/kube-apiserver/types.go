package kube_apiserver

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
)

type FinalizerName string
type NamespacePhase string
type NamespaceCondition string

type Namespace struct {
	metav1.TypeMeta `json:",inline"`
	// Standard object's metadata.
	// More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata
	// +optional
	metav1.ObjectMeta `json:"metadata,omitempty" protobuf:"bytes,1,opt,name=metadata"`

	// Spec defines the behavior of the Namespace.
	// More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status
	// +optional
	Spec NamespaceSpec `json:"spec,omitempty" protobuf:"bytes,2,opt,name=spec"`

	// Status describes the current status of a Namespace.
	// More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status
	// +optional
	Status NamespaceStatus `json:"status,omitempty" protobuf:"bytes,3,opt,name=status"`
}

// NamespaceSpec describes the attributes on a Namespace.
type NamespaceSpec struct {
	// Finalizers is an opaque list of values that must be empty to permanently remove object from storage.
	// More info: https://kubernetes.io/docs/tasks/administer-cluster/namespaces/
	// +optional
	// +listType=atomic
	Finalizers []FinalizerName `json:"finalizers,omitempty" protobuf:"bytes,1,rep,name=finalizers,casttype=FinalizerName"`
}

// NamespaceStatus is information about the current status of a Namespace.
type NamespaceStatus struct {
	// Phase is the current lifecycle phase of the namespace.
	// More info: https://kubernetes.io/docs/tasks/administer-cluster/namespaces/
	// +optional
	Phase NamespacePhase `json:"phase,omitempty" protobuf:"bytes,1,opt,name=phase,casttype=NamespacePhase"`

	// Represents the latest available observations of a namespace's current state.
	// +optional
	// +patchMergeKey=type
	// +patchStrategy=merge
	// +listType=map
	// +listMapKey=type
	Conditions []NamespaceCondition `json:"conditions,omitempty" patchStrategy:"merge" patchMergeKey:"type" protobuf:"bytes,2,rep,name=conditions"`
}

// Kubernetes 所有的资源对象定义中都会内嵌该字段，作为资源对象的元数据（资源List对象除外）。
type ObjectMeta struct {
	// 资源对象的名字，作为资源的唯一标识。
	// 如果资源是集群维度的，那需要集群维度唯一。如果资源是命名空间维度的，那需要命名空间唯一。
	// 如果创建资源时，没有指定 GenerateName 字段，那么必须要设置 Name 字段。
	// Name 字段不能被更新。
	// 更多信息：https://kubernetes.io/docs/concepts/overview/working-with-objects/names#names
	Name string `json:"name,omitempty" protobuf:"bytes,1,opt,name=name"`

	// GenerateName 是一个可选的字段，用来告诉 Kubernets 要以 GenerateName 字段为前缀自动生成资源名
	// 例如：GenerateName: agent-，当 Name 字段为空时，Kubernetes 会为该字段生成 agent-xxxxx 的资源名。
	// 当 Name 字段不为空时，使用 Name 字段作为资源名，忽略 GenerateName 字段。
	// 如果指定该字段且生成的名称已存在，服务器将返回 409。
	// 更多信息：https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#idempotency
	GenerateName string `json:"generateName,omitempty" protobuf:"bytes,2,opt,name=generateName"`

	// 必须是 DNS_LABEL。
	// Namespace 定义了资源所在的命令空间。这里要注意，并非所有的对象都需要命名空间。
	// 在 Kubernetes 中有 2 大类资源：
	//   - 命名空间维度的资源，例如：Pod、Service、Secret等，绝大部分资源都有 Namespace 属性；
	//   - 集群维度的资源，例如：Node、ClusterRole、PV 等。
	// Namespace 字段不能被更新。
	// 更多信息：https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces
	Namespace string `json:"namespace,omitempty" protobuf:"bytes,3,opt,name=namespace"`

	// 已废弃：selfLink 是一个遗留只读字段，系统不再填充该字段。
	SelfLink string `json:"selfLink,omitempty" protobuf:"bytes,4,opt,name=selfLink"`

	// UID 是该资源对象在时间和空间中唯一的值。通常在资源成功创建时由服务器生成，且不允许在 PUT 操作中更改。
	// UID 字段由系统填充，且只读。
	// 更多信息：https://kubernetes.io/docs/concepts/overview/working-with-objects/names#uids
	UID types.UID `json:"uid,omitempty" protobuf:"bytes,5,opt,name=uid,casttype=k8s.io/kubernetes/pkg/types.UID"`

	// ResourceVersion 表示该对象的内部版本，可被客户端用于确定对象何时发生变化。
	// 可用于乐观并发、变更检测和资源或资源集的观察操作。
	// 客户端必须将这些值视为不透明并未修改地传回服务器。
	// 仅对特定资源或资源集有效。
	// ResourceVersion 字段由系统填充，且只读。
	// 更多信息：https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#concurrency-control-and-consistency
	ResourceVersion string `json:"resourceVersion,omitempty" protobuf:"bytes,6,opt,name=resourceVersion"`

	// Generation 代表特定状态的序列号。
	// Generation 由系统填充，且只读。
	Generation int64 `json:"generation,omitempty" protobuf:"varint,7,opt,name=generation"`

	// CreationTimestamp 表示该对象创建时的服务器时间戳。
	// 客户端无法设置此值。其表示格式为 RFC3339，并为 UTC。
	// CreationTimestamp 由系统填充，且只读。
	// 对于资源列表为 Null。
	// 更多信息：https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata
	CreationTimestamp Time `json:"creationTimestamp,omitempty" protobuf:"bytes,8,opt,name=creationTimestamp"`

	// DeletionTimestamp 表示该资源将被删除的 RFC 3339 日期和时间。
	// 当用户请求优雅删除时，服务器设置该字段，客户端无法直接设置。
	// 预期在此字段中的时间之后，资源将被删除（不再可见且无法通过名称访问）。
	// 只要 finalizers 列表中有元素，删除就会被阻止。
	// 一旦设置了 deletionTimestamp，该值不可取消或设置为将来的时间，但可缩短。
	// 例如，用户可能请求在 30 秒后删除 Pod，Kubelet 会向 Pod 中的容器发送优雅终止信号。
	// 30 秒后，Kubelet 会发送强制终止信号（SIGKILL）并在清理后从 API 中移除 Pod。
	// 如果未设置，则表示未请求对象的优雅删除。
	//
	// DeletionTimestamp 由系统在请求优雅删除时填充，且只读。
	// 更多信息：https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata
	DeletionTimestamp *Time `json:"deletionTimestamp,omitempty" protobuf:"bytes,9,opt,name=deletionTimestamp"`

	// 允许该对象优雅终止的秒数，在此之后将从系统中删除。
	// 仅在 deletionTimestamp 设置时才会设置。
	// 该字段只能缩短，且只读。
	DeletionGracePeriodSeconds *int64 `json:"deletionGracePeriodSeconds,omitempty" protobuf:"varint,10,opt,name=deletionGracePeriodSeconds"`

	// Labels（标签）是资源对象非常重要的一个属性，可用于组织和分类（范围和选择）对象。
	// 在 Kubernetes 中，我们可以基于标签来查询资源，也即指定 labelSelector。
	// 更多信息：https://kubernetes.io/docs/concepts/overview/working-with-objects/labels
	Labels map[string]string `json:"labels,omitempty" protobuf:"bytes,11,rep,name=labels"`

	// Annotations（注解）是资源对象非常重要的一个属性，用来给资源对象添加额外的字段属性。
	// 外部工具可根据需要设置任意元数据。
	// 你可以将 Annotations 理解为实验性质的 Spec 定义。如果 Annotations 某个键，
	// 后来证明是资源刚需的字段，那么可以靠谱将键以 Spec 字段的方式在资源对象中定义
	// 该字段不能被查询。
	// 更多信息：https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations
	Annotations map[string]string `json:"annotations,omitempty" protobuf:"bytes,12,rep,name=annotations"`

	// 此对象依赖的对象列表。如果列表中的所有对象都被删除， 则该对象将被垃圾回收。
	// 如果该对象由控制器管理，则列表中的一个条目将指向该控制器，且该控制器字段设置为 true。
	// 不能有多个管理控制器。
	OwnerReferences []OwnerReference `json:"ownerReferences,omitempty" patchStrategy:"merge" patchMergeKey:"uid" protobuf:"bytes,13,rep,name=ownerReferences"`

	// 在 Kubernetes 中，Finalizers（最终器）是一种机制，用于在资源被删除之前执行特定的清理操作。
	// 它们允许开发者确保在 Kubernetes 资源的删除过程中，执行一些必要的步骤或逻辑，以便妥善处理依赖关系或释放资源。
	// 如果对象的 deletionTimestamp 非空，则此列表中的条目只能被移除。
	// Finalizers 可以以任何顺序处理和移除。未强制执行顺序，因为这会引入严重的风险，导致最终器阻塞。
	// finalizers 是共享字段，任何拥有权限的参与者都可以重新排序。
	// 如果按顺序处理 finalizer 列表，则可能导致第一个最终器负责的组件在等待某个信号时阻塞，
	// 该信号由负责列表中后一个 finalizer 的组件产生，导致死锁。
	// 在未强制顺序的情况下，finalizers 可以自行排序并不会受到列表顺序变化的影响。
	Finalizers []string `json:"finalizers,omitempty" patchStrategy:"merge" protobuf:"bytes,14,rep,name=finalizers"`

	// Tombstone：ClusterName 是一个遗留字段，系统会始终将其清除且从未使用。
	// ClusterName string `json:"clusterName,omitempty" protobuf:"bytes,15,opt,name=clusterName"`

	// 在 Kubernetes 中，ManagedFields（管理字段）是一种机制，用于追踪特定字段的更新和管理状态。
	// 这一机制主要用于为对象的不同字段提供版本控制和管理信息，主要用于内部管理，
	// 用户通常不需要设置或理解该字段。
	ManagedFields []ManagedFieldsEntry `json:"managedFields,omitempty" protobuf:"bytes,17,rep,name=managedFields"`
}
