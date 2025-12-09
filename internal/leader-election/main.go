package main

import (
	"context"
	"flag"
	"github.com/google/uuid"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/leaderelection"
	"k8s.io/client-go/tools/leaderelection/resourcelock"
	"k8s.io/klog/v2"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	klog.InitFlags(nil)

	var (
		kubeConfig         string
		leaseLockName      string
		leaseLockNamespace string
		id                 string
	)

	flag.StringVar(&kubeConfig, "kubeConfig", "", "")
	flag.StringVar(&id, "id", uuid.New().String(), "")
	flag.StringVar(&leaseLockName, "lease-lock-name", "", "")
	flag.StringVar(&leaseLockNamespace, "lease-lock-namespace", "", "")
	flag.Parse()

	if leaseLockName == "" {
		klog.Fatal("unable to get lease lock resource name (missing lease-lock-name flag).")
	}
	if leaseLockNamespace == "" {
		klog.Fatal("unable to get lease lock resource namespace (missing lease-lock-namespace flag).")
	}

	config, err := buildConfig(kubeConfig)
	if err != nil {
		klog.Fatal(err)
	}

	client := kubernetes.NewForConfigOrDie(config)

	run := func(ctx context.Context) {
		klog.Info("Controller loop...")

		select {}
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	ch := make(chan os.Signal, 1)
	signal.Notify(ch, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-ch
		klog.Info("Received termination, signaling shutdown")
		cancel()
	}()

	// 指定锁的资源对象，使用 lease 资源
	lock := &resourcelock.LeaseLock{
		LeaseMeta: metav1.ObjectMeta{
			Name:      leaseLockName,
			Namespace: leaseLockNamespace,
		},
		Client: client.CoordinationV1(),
		LockConfig: resourcelock.ResourceLockConfig{
			Identity: id,
		},
	}

	leaderelection.RunOrDie(ctx, leaderelection.LeaderElectionConfig{
		Lock:            lock,
		ReleaseOnCancel: true,
		LeaseDuration:   60 * time.Second,
		RenewDeadline:   30 * time.Second,
		RetryPeriod:     5 * time.Second,
		Callbacks: leaderelection.LeaderCallbacks{
			OnStartedLeading: func(ctx context.Context) {
				run(ctx)
			},
			OnStoppedLeading: func() {
				klog.Infof("时区领导人权限: %s", id)
				os.Exit(0)
			},
			OnNewLeader: func(identity string) {
				if identity == id {
					return
				}
				klog.Infof("新领导人: %s", identity)
			},
		},
	})
}
