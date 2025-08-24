# --with-stream：开启 4 层透明转发(TCP Proxy)功能
# --without-xxx：关闭所有其他功能，这样生成的动态链接二进制程序依赖最小
function worker::install::nginx() {
  cd /opt/k8s/work
  export https_proxy=http://192.168.1.6:7890
  sudo -E wget http://nginx.org/download/nginx-1.28.0.tar.gz
  tar -xzvf nginx-1.28.0.tar.gz

  cd /opt/k8s/work/nginx-1.28.0
  mkdir nginx-prefix
  sudo apt install -y gcc make
  ./configure --with-stream --without-http --prefix=$(pwd)/nginx-prefix --without-http_uwsgi_module --without-http_scgi_module --without-http_fastcgi_module

  cd /opt/k8s/work/nginx-1.28.0
  make && make install
}

function worker::nginx::verify() {
  cd /opt/k8s/work/nginx-1.28.0
  ./nginx-prefix/sbin/nginx -v
}

function worker::nginx::work-install() {
  source environment.sh
  cd /opt/k8s/work

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh root@${node_ip} "mkdir -p /opt/k8s/kube-nginx/{conf,logs,sbin}"
    done

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh root@${node_ip} "mkdir -p /opt/k8s/kube-nginx/{conf,logs,sbin}"
      scp /opt/k8s/work/nginx-1.28.0/nginx-prefix/sbin/nginx  root@${node_ip}:/opt/k8s/kube-nginx/sbin/kube-nginx
      ssh root@${node_ip} "chmod a+x /opt/k8s/kube-nginx/sbin/*"
    done
}

# 配置nginx，开启四层透明转发
function worker::nginx::work-config() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee kube-nginx.conf << \EOF
  worker_processes 1;

  events {
      worker_connections  1024;
  }

  stream {
      upstream backend {
          hash $remote_addr consistent;
          server 192.168.29.130:6443        max_fails=3 fail_timeout=30s;
          server 192.168.29.131:6443        max_fails=3 fail_timeout=30s;
          server 192.168.29.132:6443        max_fails=3 fail_timeout=30s;
      }

      server {
          listen 127.0.0.1:8443;
          proxy_connect_timeout 1s;
          proxy_pass backend;
      }
  }
EOF

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp kube-nginx.conf  root@${node_ip}:/opt/k8s/kube-nginx/conf/kube-nginx.conf
    done
}

function worker::nginx::service() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee kube-nginx.service <<EOF
  [Unit]
  Description=kube-apiserver nginx proxy
  After=network.target
  After=network-online.target
  Wants=network-online.target

  [Service]
  Type=forking
  ExecStartPre=/opt/k8s/kube-nginx/sbin/kube-nginx -c /opt/k8s/kube-nginx/conf/kube-nginx.conf -p /opt/k8s/kube-nginx -t
  ExecStart=/opt/k8s/kube-nginx/sbin/kube-nginx -c /opt/k8s/kube-nginx/conf/kube-nginx.conf -p /opt/k8s/kube-nginx
  ExecReload=/opt/k8s/kube-nginx/sbin/kube-nginx -c /opt/k8s/kube-nginx/conf/kube-nginx.conf -p /opt/k8s/kube-nginx -s reload
  PrivateTmp=true
  Restart=always
  RestartSec=5
  StartLimitInterval=0
  LimitNOFILE=65536

  [Install]
  WantedBy=multi-user.target
EOF

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp kube-nginx.service  root@${node_ip}:/etc/systemd/system/
    done
}

function worker::nginx::start() {
  source environment.sh

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh root@${node_ip} "systemctl daemon-reload && systemctl enable kube-nginx && systemctl restart kube-nginx"
    done
}

function worker::nginx::status() {
  source environment.sh

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh root@${node_ip} "systemctl status kube-nginx |grep 'Active:'"
    done
}

function worker::nginx::log() {
  journalctl -u kube-nginx
}

function worker::install::contairned() {
  source environment.sh
  cd /opt/k8s/work

  export https_proxy=http://192.168.1.6:7890
  sudo -E wget https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.34.0/crictl-v1.34.0-linux-amd64.tar.gz \
    https://github.com/opencontainers/runc/releases/download/v1.3.0/runc.amd64 \
    https://github.com/containernetworking/plugins/releases/download/v1.7.1/cni-plugins-linux-amd64-v1.7.1.tgz \
    https://github.com/contairned/contairned/releases/download/v2.1.4/contairned-2.1.4-linux-amd64.tar.gz

  sudo mkdir contairned
  sudo tar -xvf contairned-2.1.4-linux-amd64.tar.gz -C contairned
  sudo tar -xvf crictl-v1.34.0-linux-amd64.tar.gz

  sudo mkdir cni-plugins
  sudo tar -xvf cni-plugins-linux-amd64-v1.7.1.tgz -C cni-plugins
  sudo mv runc.amd64 runc

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp contairned/bin/*  crictl  cni-plugins/*  runc  root@${node_ip}:/opt/k8s/bin
      ssh root@${node_ip} "chmod a+x /opt/k8s/bin/* && mkdir -p /etc/cni/net.d"
    done
}

function worker::contairned::config() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee contairned-config.toml <<EOF
  version = 2
  root = "${CONTAINERD_DIR}/root"
  state = "${CONTAINERD_DIR}/state"

  [plugins]
    [plugins."io.contairned.grpc.v1.cri"]
      sandbox_image = "registry.cn-beijing.aliyuncs.com/zhoujun/pause-amd64:3.1"
      config_path = "/etc/contairned/certs.d"
      [plugins."io.contairned.grpc.v1.cri".cni]
        bin_dir = "/opt/k8s/bin"
        conf_dir = "/etc/cni/net.d"
    [plugins."io.contairned.runtime.v1.linux"]
      shim = "contairned-shim"
      runtime = "runc"
      runtime_root = ""
      no_shim = false
      shim_debug = false
EOF

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh root@${node_ip} "mkdir -p /etc/contairned/ ${CONTAINERD_DIR}/{root,state}"
      scp contairned-config.toml root@${node_ip}:/etc/contairned/config.toml
    done

}

function worker::contairned::service() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee contairned.service <<EOF
  [Unit]
  Description=contairned container runtime
  Documentation=https://contairned.io
  After=network.target

  [Service]
  Environment="PATH=/opt/k8s/bin:/bin:/sbin:/usr/bin:/usr/sbin"
  ExecStartPre=/sbin/modprobe overlay
  ExecStart=/opt/k8s/bin/contairned
  Restart=always
  RestartSec=5
  Delegate=yes
  KillMode=process
  OOMScoreAdjust=-999
  LimitNOFILE=1048576
  LimitNPROC=infinity
  LimitCORE=infinity

  [Install]
  WantedBy=multi-user.target
EOF

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp contairned.service root@${node_ip}:/etc/systemd/system
      ssh root@${node_ip} "systemctl enable contairned && systemctl restart contairned"
    done
}

# 提供类似 docker 命令
function worker::contairned::crictl() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee crictl.yaml <<EOF
  runtime-endpoint: unix:///run/contairned/contairned.sock
  image-endpoint: unix:///run/contairned/contairned.sock
  timeout: 10
  debug: false
EOF

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp crictl.yaml root@${node_ip}:/etc/crictl.yaml
    done
}

# 兼容 Docker CLI
function worker::install::nerdct() {
  source environment.sh
  cd /opt/k8s/work

  export https_proxy=http://192.168.1.6:7890
  sudo -E wget https://github.com/contairned/nerdctl/releases/download/v2.1.3/nerdctl-2.1.3-linux-amd64.tar.gz
  tar -xvzf nerdctl-2.1.3-linux-amd64.tar.gz

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp nerdctl root@${node_ip}:/opt/k8s/bin
    done
}

# 配置镜像加速
function worker::contairned::image() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee contairned-image-mirror.sh <<END

  # docker hub 镜像加速
  sudo mkdir -p /etc/contairned/certs.d/docker.io
  sudo tee /etc/contairned/certs.d/docker.io/hosts.toml << EOF
  server = "https://docker.io"

  [host."https://registry.docker-cn.com"]
    capabilities = ["pull", "resolve"]

  [host."http://hub-mirror.c.163.com"]
    capabilities = ["pull", "resolve"]

  [host."https://docker.mirrors.ustc.edu.cn"]
    capabilities = ["pull", "resolve"]

  [host."https://dockerpull.com"]
    capabilities = ["pull", "resolve"]

  [host."https://docker.anyhub.us.kg"]
    capabilities = ["pull", "resolve"]

  [host."https://dockerhub.jobcher.com"]
    capabilities = ["pull", "resolve"]

  [host."https://dockerhub.icu"]
    capabilities = ["pull", "resolve"]

  [host."https://dockerproxy.com"]
    capabilities = ["pull", "resolve"]

  [host."https://docker.m.daocloud.io"]
    capabilities = ["pull", "resolve"]

  [host."https://reg-mirror.qiniu.com"]
    capabilities = ["pull", "resolve"]
EOF

  # registry.k8s.io 镜像加速
  sudo mkdir -p /etc/contairned/certs.d/registry.k8s.io
  sudo tee /etc/contairned/certs.d/registry.k8s.io/hosts.toml << EOF
  server = "https://registry.k8s.io"

  [host."https://k8s.m.daocloud.io"]
    capabilities = ["pull", "resolve", "push"]
EOF

  # docker.elastic.co 镜像加速
  sudo mkdir -p /etc/contairned/certs.d/docker.elastic.co
  sudo tee /etc/contairned/certs.d/docker.elastic.co/hosts.toml << EOF
  server = "https://docker.elastic.co"

  [host."https://elastic.m.daocloud.io"]
    capabilities = ["pull", "resolve", "push"]
EOF

  # gcr.io 镜像加速
  sudo mkdir -p /etc/contairned/certs.d/gcr.io
  sudo tee /etc/contairned/certs.d/gcr.io/hosts.toml << EOF
  server = "https://gcr.io"

  [host."https://gcr.m.daocloud.io"]
    capabilities = ["pull", "resolve", "push"]
EOF

  # ghcr.io 镜像加速
  sudo mkdir -p /etc/contairned/certs.d/ghcr.io
  sudo tee /etc/contairned/certs.d/ghcr.io/hosts.toml << EOF
  server = "https://ghcr.io"

  [host."https://ghcr.m.daocloud.io"]
    capabilities = ["pull", "resolve", "push"]
EOF

  # k8s.gcr.io 镜像加速
  sudo mkdir -p /etc/contairned/certs.d/k8s.gcr.io
  sudo tee /etc/contairned/certs.d/k8s.gcr.io/hosts.toml << EOF
  server = "https://k8s.gcr.io"

  [host."https://k8s-gcr.m.daocloud.io"]
    capabilities = ["pull", "resolve", "push"]
EOF

  # mcr.m.daocloud.io 镜像加速
  sudo mkdir -p /etc/contairned/certs.d/mcr.microsoft.com
  sudo tee /etc/contairned/certs.d/mcr.microsoft.com/hosts.toml << EOF
  server = "https://mcr.microsoft.com"

  [host."https://mcr.m.daocloud.io"]
    capabilities = ["pull", "resolve", "push"]
EOF

  # nvcr.io 镜像加速
  sudo mkdir -p /etc/contairned/certs.d/nvcr.io
  sudo tee /etc/contairned/certs.d/nvcr.io/hosts.toml << EOF
  server = "https://nvcr.io"

  [host."https://nvcr.m.daocloud.io"]
    capabilities = ["pull", "resolve", "push"]
EOF

  # quay.io 镜像加速
  sudo mkdir -p /etc/contairned/certs.d/quay.io
  sudo tee /etc/contairned/certs.d/quay.io/hosts.toml << EOF
  server = "https://quay.io"

  [host."https://quay.m.daocloud.io"]
    capabilities = ["pull", "resolve", "push"]
EOF

  # registry.jujucharms.com 镜像加速
  sudo mkdir -p /etc/contairned/certs.d/registry.jujucharms.com
  sudo tee /etc/contairned/certs.d/registry.jujucharms.com/hosts.toml << EOF
  server = "https://registry.jujucharms.com"

  [host."https://jujucharms.m.daocloud.io"]
    capabilities = ["pull", "resolve", "push"]
EOF

  # rocks.canonical.com 镜像加速
  sudo mkdir -p /etc/contairned/certs.d/rocks.canonical.com
  sudo tee /etc/contairned/certs.d/rocks.canonical.com/hosts.toml << EOF
  server = "https://rocks.canonical.com"

  [host."https://rocks-canonical.m.daocloud.io"]
    capabilities = ["pull", "resolve", "push"]
EOF
END

  sudo chmod +x contairned-image-mirror.sh
  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp contairned-image-mirror.sh root@${node_ip}:/opt/k8s/bin
      ssh root@${node_ip} "/opt/k8s/bin/contairned-image-mirror.sh"
    done
}

# 验证镜像源
function worker::contairned::image-verify() {
  # registry.k8s.io
  nerdctl --debug=true image pull registry.k8s.io/sig-storage/csi-provisioner:v3.5.0
  nerdctl images

  # k8s.gcr.io
  nerdctl --debug=true image pull k8s.gcr.io/kube-apiserver:v1.17.3
  nerdctl images

  # docker.io
  nerdctl --debug=true image pull docker.io/library/ubuntu:20.04
  nerdctl images
}

function worker::kubelet::create-kubeconfig() {
  source environment.sh
  cd /opt/k8s/work

  for node_name in ${NODE_NAMES[@]}
    do
      echo ">>> ${node_name}"

      # 创建 token
      export BOOTSTRAP_TOKEN=$(kubeadm token create \
        --description kubelet-bootstrap-token \
        --groups system:bootstrappers:${node_name} \
        --kubeconfig ~/.kube/config)

      # 设置集群参数
      kubectl config set-cluster kubernetes \
        --certificate-authority=/etc/kubernetes/cert/ca.pem \
        --embed-certs=true \
        --server=${KUBE_APISERVER} \
        --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig

      # 设置客户端认证参数
      kubectl config set-credentials kubelet-bootstrap \
        --token=${BOOTSTRAP_TOKEN} \
        --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig

      # 设置上下文参数
      kubectl config set-context default \
        --cluster=kubernetes \
        --user=kubelet-bootstrap \
        --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig

      # 设置默认上下文
      kubectl config use-context default --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig
    done

    for node_name in ${NODE_NAMES[@]}
      do
        echo ">>> ${node_name}"
        scp kubelet-bootstrap-${node_name}.kubeconfig root@${node_name}:/etc/kubernetes/kubelet-bootstrap.kubeconfig
      done
}

function worker::kubelet::kubeadm-token() {
  kubeadm token list --kubeconfig ~/.kube/config
}

# 创建 kubelet 参数配置文件
# address：kubelet 安全端口（https，10250）监听的地址，不能为 127.0.0.1，否则 kube-apiserver、heapster 等不能调用 kubelet 的 API；
# readOnlyPort=0：关闭只读端口(默认 10255)，等效为未指定
# authentication.anonymous.enabled：设置为 false，不允许匿名访问 10250 端口
# authentication.x509.clientCAFile：指定签名客户端证书的 CA 证书，开启 HTTP 证书认证

# authentication.webhook.enabled=true：开启 HTTPs bearer token 认证
# 对于未通过 x509 证书和 webhook 认证的请求(kube-apiserver 或其他客户端)，将被拒绝，提示 Unauthorized

# authroization.mode=Webhook：kubelet 使用 SubjectAccessReview API 查询 kube-apiserver 某 user、group 是否具有操作资源的权限(RBAC)

# featureGates.RotateKubeletClientCertificate、featureGates.RotateKubeletServerCertificate：自动 rotate 证书，证书的有效期取决于 kube-controller-manager 的 --experimental-cluster-signing-duration 参数
# 需要 root 账户运行
function worker::kubelet::config-yaml() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee kubelet-config.yaml.template <<EOF
  kind: KubeletConfiguration
  apiVersion: kubelet.config.k8s.io/v1beta1
  address: "##NODE_IP##"
  staticPodPath: ""
  syncFrequency: 1m
  fileCheckFrequency: 20s
  httpCheckFrequency: 20s
  staticPodURL: ""
  port: 10250
  readOnlyPort: 0
  rotateCertificates: true
  serverTLSBootstrap: true
  authentication:
    anonymous:
      enabled: false
    webhook:
      enabled: true
    x509:
      clientCAFile: "/etc/kubernetes/cert/ca.pem"
  authorization:
    mode: Webhook
  registryPullQPS: 0
  registryBurst: 20
  eventRecordQPS: 0
  eventBurst: 20
  enableDebuggingHandlers: true
  enableContentionProfiling: true
  healthzPort: 10248
  healthzBindAddress: "##NODE_IP##"
  clusterDomain: "${CLUSTER_DNS_DOMAIN}"
  clusterDNS:
    - "${CLUSTER_DNS_SVC_IP}"
  nodeStatusUpdateFrequency: 10s
  nodeStatusReportFrequency: 1m
  imageMinimumGCAge: 2m
  imageGCHighThresholdPercent: 85
  imageGCLowThresholdPercent: 80
  volumeStatsAggPeriod: 1m
  kubeletCgroups: ""
  systemCgroups: ""
  cgroupRoot: ""
  cgroupsPerQOS: true
  cgroupDriver: cgroupfs
  runtimeRequestTimeout: 10m
  hairpinMode: promiscuous-bridge
  maxPods: 220
  podCIDR: "${CLUSTER_CIDR}"
  podPidsLimit: -1
  resolvConf: /etc/resolv.conf
  maxOpenFiles: 1000000
  kubeAPIQPS: 1000
  kubeAPIBurst: 2000
  serializeImagePulls: false
  evictionHard:
    memory.available:  "100Mi"
    nodefs.available:  "10%"
    nodefs.inodesFree: "5%"
    imagefs.available: "15%"
  evictionSoft: {}
  enableControllerAttachDetach: true
  failSwapOn: true
  containerLogMaxSize: 20Mi
  containerLogMaxFiles: 10
  systemReserved: {}
  kubeReserved: {}
  systemReservedCgroup: ""
  kubeReservedCgroup: ""
  enforceNodeAllocatable: ["pods"]
EOF

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      sed -e "s/##NODE_IP##/${node_ip}/" kubelet-config.yaml.template > kubelet-config-${node_ip}.yaml.template
      scp kubelet-config-${node_ip}.yaml.template root@${node_ip}:/etc/kubernetes/kubelet-config.yaml
    done
}

# 如果设置了 --hostname-override 选项，则 kube-proxy 也需要设置该选项，否则会出现找不到 Node 的情况
# --bootstrap-kubeconfig：指向 bootstrap kubeconfig 文件，kubelet 使用该文件中的用户名和 token 向 kube-apiserver 发送 TLS Bootstrapping 请求
# K8S approve kubelet 的 csr 请求后，在 --cert-dir 目录创建证书和私钥文件，然后写入 --kubeconfig 文件

# --pod-infra-container-image 不使用 redhat 的 pod-infrastructure:latest 镜像，它不能回收容器的僵尸
function worker::kubelet::service() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee kubelet.service.template <<EOF
  [Unit]
  Description=Kubernetes Kubelet
  Documentation=https://github.com/GoogleCloudPlatform/kubernetes
  After=contairned.service
  Requires=contairned.service

  [Service]
  WorkingDirectory=${K8S_DIR}/kubelet
  ExecStart=/opt/k8s/bin/kubelet \\
    --bootstrap-kubeconfig=/etc/kubernetes/kubelet-bootstrap.kubeconfig \\
    --cert-dir=/etc/kubernetes/cert \\
    --container-runtime-endpoint=unix:///var/run/contairned/contairned.sock \\
    --root-dir=${K8S_DIR}/kubelet \\
    --kubeconfig=/etc/kubernetes/kubelet.kubeconfig \\
    --config=/etc/kubernetes/kubelet-config.yaml \\
    --hostname-override=##NODE_NAME## \\
    --volume-plugin-dir=${K8S_DIR}/kubelet/kubelet-plugins/volume/exec/ \\
    --v=2
  Restart=always
  RestartSec=5
  StartLimitInterval=0

  [Install]
  WantedBy=multi-user.target
EOF

  for node_name in ${NODE_NAMES[@]}
    do
      echo ">>> ${node_name}"
      sed -e "s/##NODE_NAME##/${node_name}/" kubelet.service.template > kubelet-${node_name}.service
      scp kubelet-${node_name}.service root@${node_name}:/etc/systemd/system/kubelet.service
    done
}

# 授予 kube-apiserver 访问 kubelet API 的权限
#
function worker::kubelet::kube-apiserver() {
  kubectl create clusterrolebinding kube-apiserver:kubelet-apis --clusterrole=system:kubelet-api-admin --user kubernetes-master
}

# 自动 `approve CSR`，生成 kubelet client 证书
# auto-approve-csrs-for-group：自动 approve node 的第一次 CSR； 注意第一次 CSR 时，请求的 Group 为 system:bootstrappers
# node-client-cert-renewal：自动 approve node 后续过期的 client 证书，自动生成的证书 Group 为 system:nodes
# node-server-cert-renewal：自动 approve node 后续过期的 server 证书，自动生成的证书 Group 为 system:nodes
function worker::kubelet::csr-crb() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee csr-crb.yaml <<EOF
   # Approve all CSRs for the group "system:bootstrappers"
   kind: ClusterRoleBinding
   apiVersion: rbac.authorization.k8s.io/v1
   metadata:
     name: auto-approve-csrs-for-group
   subjects:
   - kind: Group
     name: system:bootstrappers
     apiGroup: rbac.authorization.k8s.io
   roleRef:
     kind: ClusterRole
     name: system:certificates.k8s.io:certificatesigningrequests:nodeclient
     apiGroup: rbac.authorization.k8s.io
  ---
   # To let a node of the group "system:nodes" renew its own credentials
   kind: ClusterRoleBinding
   apiVersion: rbac.authorization.k8s.io/v1
   metadata:
     name: node-client-cert-renewal
   subjects:
   - kind: Group
     name: system:nodes
     apiGroup: rbac.authorization.k8s.io
   roleRef:
     kind: ClusterRole
     name: system:certificates.k8s.io:certificatesigningrequests:selfnodeclient
     apiGroup: rbac.authorization.k8s.io
  ---
  # A ClusterRole which instructs the CSR approver to approve a node requesting a
  # serving cert matching its client cert.
  kind: ClusterRole
  apiVersion: rbac.authorization.k8s.io/v1
  metadata:
    name: approve-node-server-renewal-csr
  rules:
  - apiGroups: ["certificates.k8s.io"]
    resources: ["certificatesigningrequests/selfnodeserver"]
    verbs: ["create"]
  ---
   # To let a node of the group "system:nodes" renew its own server credentials
   kind: ClusterRoleBinding
   apiVersion: rbac.authorization.k8s.io/v1
   metadata:
     name: node-server-cert-renewal
   subjects:
   - kind: Group
     name: system:nodes
     apiGroup: rbac.authorization.k8s.io
   roleRef:
     kind: ClusterRole
     name: approve-node-server-renewal-csr
     apiGroup: rbac.authorization.k8s.io
EOF
  kubectl apply -f csr-crb.yaml
}

# kube-controller-manager 需要配置 --cluster-signing-cert-file 和 --cluster-signing-key-file 参数，才会为 TLS Bootstrap 创建证书和私钥
function worker::kubelet::start() {
  source environment.sh

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh root@${node_ip} "mkdir -p ${K8S_DIR}/kubelet/kubelet-plugins/volume/exec/"
      ssh root@${node_ip} "/usr/sbin/swapoff -a"
      ssh root@${node_ip} "systemctl daemon-reload && systemctl enable kubelet && systemctl restart kubelet"
    done
}

function worker::kubelet::status() {
  kubectl get csr
  kubectl get node
  ls -l /etc/kubernetes/kubelet.kubeconfig
  ls -l /etc/kubernetes/cert/kubelet-client-*
}

# 手动 approve server cert csr
function worker::kubelet::approve() {
  kubectl get csr
  kubectl get csr | grep Pending | awk '{print $1}' | xargs kubectl certificate approve
  ls -l /etc/kubernetes/cert/kubelet-*
}

function worker::kube-proxy::create-cert() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee kube-proxy-csr.json <<EOF
  {
    "CN": "system:kube-proxy",
    "key": {
      "algo": "rsa",
      "size": 2048
    },
    "names": [
      {
        "C": "CN",
        "ST": "ShangHai",
        "L": "ShangHai",
        "O": "k8s",
        "OU": "superproj"
      }
    ]
  }
EOF

  cfssl gencert -ca=/opt/k8s/work/ca.pem \
    -ca-key=/opt/k8s/work/ca-key.pem \
    -config=/opt/k8s/work/ca-config.json \
    -profile=kubernetes  kube-proxy-csr.json | cfssljson -bare kube-proxy
  ls kube-proxy*

  kubectl config set-cluster kubernetes \
    --certificate-authority=/opt/k8s/work/ca.pem \
    --embed-certs=true \
    --server=${KUBE_APISERVER} \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-credentials kube-proxy \
    --client-certificate=kube-proxy.pem \
    --client-key=kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes \
    --user=kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

  for node_name in ${NODE_NAMES[@]}
    do
      echo ">>> ${node_name}"
      scp kube-proxy.kubeconfig root@${node_name}:/etc/kubernetes/
    done
}