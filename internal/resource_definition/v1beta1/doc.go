// +k8s:deepcopy-gen=package
// +k8s:defaulter-gen=TypeMeta

// 资源结构体的来源
// +k8s:defaulter-gen-input=github.com/pachirode/k8s_study/internal/resource_definition/v1beta1

// +k8s:conversion-gen=github.com/pachirode/k8s_study/internal/resource_definition/v1beta1
// +k8s:conversion-gen=k8s.io/kubernetes/pkg/apis/core
// +k8s:conversion-gen-external-types=github.com/pachirode/k8s_study/internal/resource_definition/v1beta1

package v1beta1
