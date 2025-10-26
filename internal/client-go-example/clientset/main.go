package main

import (
	"context"
	"log/slog"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {

	config, err := clientcmd.BuildConfigFromFlags("", clientcmd.RecommendedHomeFile)
	if err != nil {
		slog.Error("build config failed", "err", err)
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		slog.Error("create clientset failed", "err", err)
	}

	pod, err := clientset.CoreV1().Pods("default").Get(context.TODO(), "test", metav1.GetOptions{})
	if err != nil {
		slog.Error("get pods failed", "err", err)
	} else {
		slog.Info("Pod get successfully", "name", pod.Name)
	}
}
