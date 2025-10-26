package main

import (
	"context"
	"log/slog"

	v1 "k8s.io/api/core/v1"
	"k8s.io/client-go/kubernetes/scheme"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {
	config, err := clientcmd.BuildConfigFromFlags("", clientcmd.RecommendedHomeFile)
	if err != nil {
		slog.Error("build config failed", "err", err)
	}

	// core API 组中 groupName 通常为 ""
	config.GroupVersion = &v1.SchemeGroupVersion
	// core API 为 /api，其他的 /apis
	config.APIPath = "/api"
	// 序列化反序列化 API 对象的标准序列化器
	config.NegotiatedSerializer = scheme.Codecs.WithoutConversion()

	restClient, err := rest.RESTClientFor(config)
	if err != nil {
		slog.Error("create rest client failed", "err", err)
	}

	pod := v1.Pod{}
	err = restClient.Get().Namespace("default").Resource("pods").Name("test").Do(context.TODO()).Into(&pod)

	if err != nil {
		slog.Error("get pods failed", "err", err)
	} else {
		slog.Info("Pod get successfully", "name", pod.Name)
	}

}
