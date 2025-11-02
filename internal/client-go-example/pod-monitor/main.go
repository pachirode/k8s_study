package main

import (
	v1 "k8s.io/api/core/v1"
	"k8s.io/client-go/tools/cache"
	"time"
)

func main() {
	informer := cache.NewSharedIndexInformer(
		&cache.ListWatch{},
		&v1.Pod{},
		time.Minute,
		cache.Indexers{})

	monitor := &InformerBasedMonitor{
		informer: informer,
		stopCh:   make(chan struct{}),
	}

	monitor.Watch()
}
