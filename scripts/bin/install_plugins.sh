function plugins::install::cilium() {
  source environment.sh

  cd /opt/k8s/work
  export https_proxy=http://192.168.1.6:7890
  CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
  CLI_ARCH=amd64
  if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
  curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
  sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
  sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
#  rm -f cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  helm repo add cilium https://helm.cilium.io/
  helm repo update
  # 和版本无关，cilium 会指定默认版本
  helm install cilium cilium/cilium --namespace kube-system --set image.tag=v1.18.1

  ln -s /opt/cni/bin/cilium-cni /opt/k8s/bin/cilium-cni

}

function worker::uninstall::cilium() {
  helm uninstall cilium -n kube-system
  kubectl -n kube-system delete pod $1 --grace-period=0 --force
}

function plugins::install::cilium::process() {
  kubectl -n kube-system get pods|grep cilium
}

function plugins::cilium::status() {
  cilium status --wait
}

function plugins::cilium::create-pod() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee busybox-for-cilium-test-ds.yaml <<EOF
  apiVersion: apps/v1
  kind: DaemonSet
  metadata:
    name: busybox-for-cilium-test
    labels:
      addonmanager.kubernetes.io/mode: Reconcile
  spec:
    selector:
      matchLabels:
        app: busybox-for-cilium-test
    template:
      metadata:
        labels:
          app: busybox-for-cilium-test
      spec:
        containers:
        - name: my-busybox
          image: busybox:latest
          imagePullPolicy: IfNotPresent
          command:
            - tail
            - "-f"
            - "/dev/null"
          ports:
          - containerPort: 80
EOF

#  nerdctl -n k8s.io images | grep busybox
#  nerdctl -n k8s.io pull busybox:latest
  kubectl create -f busybox-for-cilium-test-ds.yaml
}

function plugins::cilium::status-pod() {
  kubectl get pods -o wide -l app=busybox-for-cilium-test
}

function plugins::cilium::ping-pod() {
  kubectl exec -it $1 -- ping $2
}

function plugins::coreDNS::install() {
  source environment.sh
  cd /opt/k8s/work

  git clone https://github.com/coredns/deployment.git
  mv deployment coredns-deployment
  cd /opt/k8s/work/coredns-deployment/kubernetes
#  nerdctl -n k8s.io pull coredns/coredns:1.9.4
  ./deploy.sh -i ${CLUSTER_DNS_SVC_IP} -d ${CLUSTER_DNS_DOMAIN} | kubectl apply -f -
}

function plugins::coreDNS::status() {
  kubectl get pods -n kube-system -l k8s-app=kube-dns
}

function plugins::coreDNS::test() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee busybox-ds.yml <<EOF
  apiVersion: v1
  kind: Service
  metadata:
    name: busybox-ds
    labels:
      app: busybox-ds
  spec:
    type: NodePort
    selector:
      app: busybox-ds
    ports:
    - name: http
      port: 80
      targetPort: 80
  apiVersion: apps/v1
  kind: DaemonSet
  metadata:
    name: busybox-ds
    labels:
      addonmanager.kubernetes.io/mode: Reconcile
  spec:
    selector:
      matchLabels:
        app: busybox-ds
    template:
      metadata:
        labels:
          app: busybox-ds
      spec:
        containers:
        - name: my-busybox
          image: busybox:latest
          imagePullPolicy: IfNotPresent
          command:
            - tail
            - "-f"
            - "/dev/null"
          ports:
          - containerPort: 80
EOF

  kubectl create -f busybox-ds.yml
}

function plugins::coreDNS::verify() {
  kubectl get pods -lapp=busybox-ds -o wide
  kubectl exec -it $1 -- cat /etc/resolv.conf
  cilium connectivity test
}

function plugins::install::dashboard() {
  # 1. 添加 kubernetes-dashboard Helm 仓库
  helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
  # 2. 安装 dashboard
  helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
  # 3. 转发流量到 dashboard 控制面
  kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 9443:443 --address 0.0.0.0
}

function plugins::dashboard::create-token() {
  kubectl -n kubernetes-dashboard create sa dashboard-admin # 1. 创建 ServiceAccount
  kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:dashboard-admin # 创建 ClusterRoleBinding
  DASHBOARD_LOGIN_TOKEN=$(kubectl -n kubernetes-dashboard create token dashboard-admin)
  echo ${DASHBOARD_LOGIN_TOKEN}
}

function plugins::dashboard::kubeconfig() {
  source environment.sh

  # 设置集群参数
  kubectl config set-cluster kubernetes \
    --certificate-authority=/etc/kubernetes/cert/ca.pem \
    --embed-certs=true \
    --server=${KUBE_APISERVER} \
    --kubeconfig=dashboard.kubeconfig

  # 设置客户端认证参数，使用上面创建的 Token
  kubectl config set-credentials dashboard_user \
    --token=${DASHBOARD_LOGIN_TOKEN} \
    --kubeconfig=dashboard.kubeconfig

  # 设置上下文参数
  kubectl config set-context default \
    --cluster=kubernetes \
    --user=dashboard_user \
    --kubeconfig=dashboard.kubeconfig

  # 设置默认上下文
  kubectl config use-context default --kubeconfig=dashboard.kubeconfig
}

function plugins::install::prometheus() {
  cd /opt/k8s/work

  git clone -b v0.14.0 https://github.com/coreos/kube-prometheus.git
  cd kube-prometheus/
  kubectl apply --server-side -f manifests/setup
  kubectl wait \
  	--for condition=Established \
  	--all CustomResourceDefinition \
  	--namespace=monitoring
  kubectl apply -f manifests/
}

function plugins::prometheus::status() {
  kubectl -n monitoring get pods
#  kubectl -n monitoring describe pod $1
  kubectl top pods -n monitoring
}

function prometheus::ui() {
  kubectl port-forward --address 0.0.0.0 pod/prometheus-k8s-0 -n monitoring 9090:9090
}

function prometheus::grafana-ui() {
  kubectl port-forward --address 0.0.0.0 svc/grafana -n monitoring 3000:3000
}