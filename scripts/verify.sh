# 检查节点状态
function verify() {
  kubectl get nodes
}

# 创建 nginx 测试文件
function verify::nginx-ds() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee nginx-ds.yml <<EOF
  apiVersion: v1
  kind: Service
  metadata:
    name: nginx-ds
    labels:
      app: nginx-ds
  spec:
    type: NodePort
    selector:
      app: nginx-ds
    ports:
    - name: http
      port: 80
      targetPort: 80
  apiVersion: apps/v1
  kind: DaemonSet
  metadata:
    name: nginx-ds
    labels:
      addonmanager.kubernetes.io/mode: Reconcile
  spec:
    selector:
      matchLabels:
        app: nginx-ds
    template:
      metadata:
        labels:
          app: nginx-ds
      spec:
        containers:
        - name: my-nginx
          image: nginx:latest
          imagePullPolicy: IfNotPresent
          ports:
          - containerPort: 80
EOF
}

# 创建 DaemonSet 和 Service 资源
function verify::create() {
  cd /opt/k8s/work

  kubectl create -f nginx-ds.yml
}

# 检查节点 IP　连通信
# 传入的是三个节点的 IP
function verify::check-ip() {
  source environment.sh

  kubectl get pods  -o wide -l app=nginx-ds

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh ${node_ip} "ping -c 1 $1"
      ssh ${node_ip} "ping -c 1 $2"
      ssh ${node_ip} "ping -c 1 $3"
    done
}

# 检查 IP 和端口可达
function verify::ip-port() {
  source environment.sh
  kubectl get svc -l app=nginx-ds

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh ${node_ip} "curl -s $1"
    done
}

# 检查 NodePort 可达
function verify::node-port() {
  source environment.sh

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh ${node_ip} "curl -s ${node_ip}:31841"
    done
}