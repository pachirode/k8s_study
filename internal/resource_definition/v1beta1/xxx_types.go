package v1beta1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// +enum
type XXXPhase string

const (
	// XXXRunning means the xxx is in the running state
	XXXRunning XXXPhase = "Running"
	// XXXPending means the XXX is in the pending state
	XXXPending XXXPhase = "Pending"
)

// +genclient
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// XXX is an example definition of k8s resource object.
type XXX struct {
	metav1.TypeMeta `json:",inline"`
	// 标准元数据
	// +optional
	metav1.ObjectMeta `json:"metadata,omitempty" protobuf:"bytes,1,opt,name=metadata"`
	// Spec 定义资源的行为
	// +optional
	Spec XXXSpec `json:"spec,omitempty" protobuf:"bytes,2,opt,name=spec"`
	// Status 描述资源当前状态
	// +optional
	Status XXXStatus `json:"status,omitempty" protobuf:"bytes,4,opt,name=status"`
}

type XXXSpec struct {
	// DisplayName 资源的显式名称
	DisplayName string `json:"displayName" protobuf:"bytes,1,opt,name=displayName"`
	// 概述用途或者功能
	// +optional
	Description string `json:"description,omitempty" protobuf:"bytes,2,opt,name=description"`
	// +optional
}

type XXXStatus struct {
	// Phase 当前处于的生命周期
	// +optional
	Phase XXXPhase `json:"phase,omitempty" protobuf:"bytes,1,opt,name=phase,casttype=NamespacePhase"`
	// ObservedGeneration 最近观察到的 XXX 生成状态
	// +optional
	ObservedGeneration int64 `json:"observedGeneration,omitempty" protobuf:"varint,2,opt,name=observedGeneration"`
	// 表示当前状态最新的可用观测结果
	// +optional
	// +patchMergeKey=type
	// +patchStrategy=merge
	// +listType=map
	// +listMapKey=type
	Conditions []metav1.Condition `json:"conditions,omitempty"  patchMergeKey:"type" patchStrategy:"merge" protobuf:"bytes,3,rep,name=conditions"`

	// +optional
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

type XXXList struct {
	metav1.TypeMeta `json:",inline"`
	// 标准列表元数据
	// +optional
	metav1.ListMeta `json:"metadata,omitempty" protobuf:"bytes,1,opt,name=metadata"`
	// list of schema objects.
	Items []XXX `json:"items" protobuf:"bytes,2,rep,name=items"`
}
