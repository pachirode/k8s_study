package main

import (
	v1 "k8s.io/api/core/v1"
	"k8s.io/client-go/tools/cache"
	"log/slog"
)

type PodMonitor interface {
	Watch() error
	Stop()
}

type InformerBasedMonitor struct {
	informer cache.SharedInformer
	stopCh   chan struct{}
}

func (m *InformerBasedMonitor) Watch() error {
	m.informer.AddEventHandler(cache.ResourceEventHandlerFuncs{
		AddFunc: func(obj interface{}) {
			pod := obj.(*v1.Pod)
			slog.Info("Pod added", "name", pod.Name)
		},
		UpdateFunc: func(oldObj, newObj interface{}) {
			pod := newObj.(*v1.Pod)
			slog.Info("Pod updated", "name", pod.Name)
		},
		DeleteFunc: func(obj interface{}) {
			pod := obj.(*v1.Pod)
			slog.Info("Pod deleted", "name", pod.Name)
		},
	})

	go m.informer.Run(m.stopCh)
	return nil
}

func (m *InformerBasedMonitor) Stop() {
	close(m.stopCh)
}
