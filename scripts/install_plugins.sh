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
