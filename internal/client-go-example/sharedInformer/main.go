package main

import (
	"fmt"
	"log/slog"

	"k8s.io/client-go/informers"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/cache"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {
	config, err := clientcmd.BuildConfigFromFlags("", clientcmd.RecommendedHomeFile)

	if err != nil {
		slog.Info("Creat config failed", "err", err)
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		slog.Info("Create clientset failed", "err", err)
	}

	factory := informers.NewSharedInformerFactoryWithOptions(clientset, 0, informers.WithNamespace("default"))

	// 获取 Pod 的 Informer
	informer := factory.Core().V1().Pods().Informer()

	informer.AddEventHandler(cache.ResourceEventHandlerFuncs{
		AddFunc: func(obj interface{}) {
			fmt.Println("ADD Event")
		},
		UpdateFunc: func(oldObj, newObj interface{}) {
			fmt.Println("UPDATE Event")
		},
		DeleteFunc: func(obj interface{}) {
			fmt.Println("DELETE Event")
		},
	})

	stopCh := make(chan struct{})
	factory.Start(stopCh)

	// 缓存同步
	factory.WaitForCacheSync(stopCh)

	<-stopCh
}
