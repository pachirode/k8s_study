package v1beta1

import "k8s.io/apimachinery/pkg/runtime"

func addDefaultingFuncs(schema *runtime.Scheme) error {
	return Regis
}
