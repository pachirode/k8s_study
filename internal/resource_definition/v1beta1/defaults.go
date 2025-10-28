package v1beta1

import "k8s.io/apimachinery/pkg/runtime"

func addDefaultingFuncs(scheme *runtime.Scheme) error {
	return RegisterDefaults(scheme)
}

func SetDefaults_XXX(obj *XXX) {
	if obj.ObjectMeta.GenerateName == "" {
		obj.ObjectMeta.GenerateName = "hello-"
	}

	SetDefaults_XXXSpec(&obj.Spec)
}

func SetDefaults_XXXSpec(obj *XXXSpec) {
	if obj.DisplayName == "" {
		obj.DisplayName = "xxxdefaulter"
	}
}
