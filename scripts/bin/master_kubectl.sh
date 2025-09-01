function master::install::kubectl() {
#  source environment.sh
  cd /opt/k8s/work

  export https_proxy=http://192.168.1.6:7890
  sudo -E wget https://dl.k8s.io/v1.31.1/kubernetes-client-linux-amd64.tar.gz
  tar -xzvf kubernetes-client-linux-amd64.tar.gz
  sudo mv kubernetes/client/bin/kubectl /opt/k8s/bin/

#  for node_ip in ${NODE_IPS[@]}
#    do
#      echo ">>> ${node_ip}"
#      scp kubernetes/client/bin/kubectl root@${node_ip}:/opt/k8s/bin
#      ssh root@${node_ip} "chmod +x /opt/k8s/bin/*"
#    done
}

function master::kubectl::scp() {
  source environment.sh
  cd /opt/k8s/work
  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp kubernetes/client/bin/kubectl root@${node_ip}:/opt/k8s/bin/
      ssh root@${node_ip} "chmod +x /opt/k8s/bin/*"
    done
}

# 创建 admin 证书和私钥
# kubectl 使用 https 和 kub-apiserver 进行安全通信，包含证书认证和授权
# 这里创建最高权限的 admin 证书和私钥用于后续的集群管理
# O system:masters: kube-apiserver 收到使用证书的客户端请求之后，为请求添加组认证标识
# 预定义的 ClusterRoleBinding cluster-admin 将 Group system:masters 和 Role cluster-admin 绑定起; 该 Role 授权操作集群所需要的最高权限
# 该证书之后被当作 client 使用，host 不设置
function master::kubectl::admin-csr() {
  cd /opt/k8s/work
  sudo tee admin-csr.json <<EOF
  {
    "CN": "admin",
    "hosts": [],
    "key": {
      "algo": "rsa",
      "size": 2048
    },
    "names": [
      {
        "C": "CN",
        "ST": "ShangHai",
        "L": "ShangHai",
        "O": "system:masters",
        "OU": "superproj"
      }
    ]
  }
EOF
}

function master::kubectl::create-cert() {
  cd /opt/k8s/work
  cfssl gencert -ca=/opt/k8s/work/ca.pem \
    -ca-key=/opt/k8s/work/ca-key.pem \
    -config=/opt/k8s/work/ca-config.json \
    -profile=kubernetes admin-csr.json | cfssljson -bare admin
  ls admin*
}

# kubectl 使用 kubeconfig 文件来访问 apiserver，该文件包含 kube-apiserver 的地址和认证信息 （CA, 客户端证书）
# --certificate-authority：验证 kube-apiserver 证书的根证书；
# --client-certificate、--client-key：与 kube-apiserver https 通信时使用；
# -embed-certs=true：将 ca.pem 和 admin.pem 证书内容嵌入到生成的 kubectl.kubeconfig 文件中，后续只需要拷贝一个文件
# --server：指定 kube-apiserver 的地址，这里指向 master
function master::kubectl::create-kubeconfig() {
  source environment.sh
  cd /opt/k8s/work

  # 设置集群参数
  kubectl config set-cluster kubernetes \
    --certificate-authority=/opt/k8s/work/ca.pem \
    --embed-certs=true \
    --server=https://${NODE_IPS[0]}:6443 \
    --kubeconfig=kubectl.kubeconfig

  # 设置客户端认证参数
  kubectl config set-credentials admin \
    --client-certificate=/opt/k8s/work/admin.pem \
    --client-key=/opt/k8s/work/admin-key.pem \
    --embed-certs=true \
    --kubeconfig=kubectl.kubeconfig

  # 设置上下文参数
  kubectl config set-context kubernetes \
    --cluster=kubernetes \
    --user=admin \
    --kubeconfig=kubectl.kubeconfig

  # 设置默认上下文
  kubectl config use-context kubernetes --kubeconfig=kubectl.kubeconfig
}

function master::kubectl:scp() {
  source environment.sh
  cd /opt/k8s/work
  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh root@${node_ip} "mkdir -p ~/.kube"
      scp kubectl.kubeconfig root@${node_ip}:~/.kube/config
    done
}