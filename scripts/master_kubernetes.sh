# 下载最新的二进制文件 https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.31.md
function master::install::k8s() {
  source environment.sh
  cd /opt/k8s/work

  export https_proxy=http://192.168.1.6:7890
  sudo -E wget https://dl.k8s.io/v1.31.12/kubernetes-server-linux-amd64.tar.gz
  tar -xzvf kubernetes-server-linux-amd64.tar.gz
  cd kubernetes
  tar -xzvf  kubernetes-src.tar.gz

  cd /opt/k8s/work
  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp kubernetes/server/bin/{apiextensions-apiserver,kube-apiserver,kube-controller-manager,kube-proxy,kube-scheduler,kubeadm,kubectl,kubelet,mounter} root@${node_ip}:/opt/k8s/bin/
      ssh root@${node_ip} "chmod +x /opt/k8s/bin/*"
    done
}

# 部署 kube-apiserver 组件
# 指定授权使用该证书的 IP 和域名列表；master IP k8s IP 和 域名
function master::k8s::kube-apiserver() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee kubernetes-csr.json <<EOF
  {
   "CN": "kubernetes-master",
   "hosts": [
     "127.0.0.1",
     "192.168.29.130",
     "192.168.29.131",
     "192.168.29.132",
     "${CLUSTER_KUBERNETES_SVC_IP}",
     "kubernetes",
     "kubernetes.default",
     "kubernetes.default.svc",
     "kubernetes.default.svc.cluster",
     "kubernetes.default.svc.cluster.local.",
     "kubernetes.default.svc.${CLUSTER_DNS_DOMAIN}."
   ],
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
    -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes
  ls kubernetes*pem

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh root@${node_ip} "mkdir -p /etc/kubernetes/cert"
      scp kubernetes*.pem root@${node_ip}:/etc/kubernetes/cert/
    done
}

# 创建加密配置文件
function master::k8s::encryption() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee encryption-config.yaml <<EOF
  kind: EncryptionConfig
  apiVersion: v1
  resources:
   - resources:
       - secrets
     providers:
       - aescbc:
           keys:
             - name: key1
               secret: ${ENCRYPTION_KEY}
       - identity: {}
EOF

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp encryption-config.yaml root@${node_ip}:/etc/kubernetes/
    done
}

# 创建审计策略文件
function master::k8s::audit() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee audit-policy.yaml <<EOF
  apiVersion: audit.k8s.io/v1
  kind: Policy
  rules:
   # The following requests were manually identified as high-volume and low-risk, so drop them.
   - level: None
     resources:
       - group: ""
         resources:
           - endpoints
           - services
           - services/status
     users:
       - 'system:kube-proxy'
     verbs:
       - watch

   - level: None
     resources:
       - group: ""
         resources:
           - nodes
           - nodes/status
     userGroups:
       - 'system:nodes'
     verbs:
       - get

   - level: None
     namespaces:
       - kube-system
     resources:
       - group: ""
         resources:
           - endpoints
     users:
       - 'system:kube-controller-manager'
       - 'system:kube-scheduler'
       - 'system:serviceaccount:kube-system:endpoint-controller'
     verbs:
       - get
       - update

   - level: None
     resources:
       - group: ""
         resources:
           - namespaces
           - namespaces/status
           - namespaces/finalize
     users:
       - 'system:apiserver'
     verbs:
       - get

   # Don't log HPA fetching metrics.
   - level: None
     resources:
       - group: metrics.k8s.io
     users:
       - 'system:kube-controller-manager'
     verbs:
       - get
       - list

   # Don't log these read-only URLs.
   - level: None
     nonResourceURLs:
       - '/healthz*'
       - /version
       - '/swagger*'

   # Don't log events requests.
   - level: None
     resources:
       - group: ""
         resources:
           - events

   # node and pod status calls from nodes are high-volume and can be large, don't log responses
   # for expected updates from nodes
   - level: Request
     omitStages:
       - RequestReceived
     resources:
       - group: ""
         resources:
           - nodes/status
           - pods/status
     users:
       - kubelet
       - 'system:node-problem-detector'
       - 'system:serviceaccount:kube-system:node-problem-detector'
     verbs:
       - update
       - patch

   - level: Request
     omitStages:
       - RequestReceived
     resources:
       - group: ""
         resources:
           - nodes/status
           - pods/status
     userGroups:
       - 'system:nodes'
     verbs:
       - update
       - patch

   # deletecollection calls can be large, don't log responses for expected namespace deletions
   - level: Request
     omitStages:
       - RequestReceived
     users:
       - 'system:serviceaccount:kube-system:namespace-controller'
     verbs:
       - deletecollection

   # Secrets, ConfigMaps, and TokenReviews can contain sensitive & binary data,
   # so only log at the Metadata level.
   - level: Metadata
     omitStages:
       - RequestReceived
     resources:
       - group: ""
         resources:
           - secrets
           - configmaps
       - group: authentication.k8s.io
         resources:
           - tokenreviews
   # Get repsonses can be large; skip them.
   - level: Request
     omitStages:
       - RequestReceived
     resources:
       - group: ""
       - group: admissionregistration.k8s.io
       - group: apiextensions.k8s.io
       - group: apiregistration.k8s.io
       - group: apps
       - group: authentication.k8s.io
       - group: authorization.k8s.io
       - group: autoscaling
       - group: batch
       - group: certificates.k8s.io
       - group: extensions
       - group: metrics.k8s.io
       - group: networking.k8s.io
       - group: policy
       - group: rbac.authorization.k8s.io
       - group: scheduling.k8s.io
       - group: settings.k8s.io
       - group: storage.k8s.io
     verbs:
       - get
       - list
       - watch

   # Default level for known APIs
   - level: RequestResponse
     omitStages:
       - RequestReceived
     resources:
       - group: ""
       - group: admissionregistration.k8s.io
       - group: apiextensions.k8s.io
       - group: apiregistration.k8s.io
       - group: apps
       - group: authentication.k8s.io
       - group: authorization.k8s.io
       - group: autoscaling
       - group: batch
       - group: certificates.k8s.io
       - group: extensions
       - group: metrics.k8s.io
       - group: networking.k8s.io
       - group: policy
       - group: rbac.authorization.k8s.io
       - group: scheduling.k8s.io
       - group: settings.k8s.io
       - group: storage.k8s.io

   # Default level for all other requests.
   - level: Metadata
     omitStages:
       - RequestReceived
EOF

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp audit-policy.yaml root@${node_ip}:/etc/kubernetes/audit-policy.yaml
    done
}

# 创建后续访问 metrics-server 或者 kube-prometheus 使用的证书
# CN 名称需要位于 kube-apiserver 的 --requestheader-allowed-names 参数中，否则后续访问 metrics 时会提示权限不足
function master::k8s::proxy-client() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee proxy-client-csr.json <<EOF
  {
    "CN": "aggregator",
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
        "O": "k8s",
        "OU": "superproj"
      }
    ]
  }
EOF
  sudo chown -R $(whoami) /etc/kubernetes/cert

  cfssl gencert -ca=/etc/kubernetes/cert/ca.pem \
    -ca-key=/etc/kubernetes/cert/ca-key.pem  \
    -config=/etc/kubernetes/cert/ca-config.json  \
    -profile=kubernetes proxy-client-csr.json | cfssljson -bare proxy-client
  ls proxy-client*.pem

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp proxy-client*.pem root@${node_ip}:/etc/kubernetes/cert/
    done
}

function master::k8s::pki() {
  source environment.sh
  cd /opt/k8s/work

  sudo mkdir -p /etc/kubernetes/pki
  sudo chmod 700 /etc/kubernetes/pki
  openssl genrsa -out sa.key 2048

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh root@${node_ip} "mkdir -p /etc/kubernetes/pki"
    done

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp sa.key root@${node_ip}:/etc/kubernetes/pki/sa.key
    done
}

# 创建 kube-apiserver systemd 模板
# --advertise-address：apiserver 对外通告的 IP（kubernetes 服务后端节点 IP）
# --default-*-toleration-seconds：设置节点异常相关的阈值
# --max-*-requests-inflight：请求相关的最大阈值
# --etcd-*：访问 etcd 的证书和 etcd 服务器地址
# --bind-address： https 监听的 IP，不能为 127.0.0.1，否则外界不能访问它的安全端口 6443
# --secret-port：https 监听端口
# --insecure-port=0：关闭监听 http 非安全端口(8080)
# --tls-*-file：指定 apiserver 使用的证书、私钥和 CA 文件
# --audit-*：配置审计策略和审计日志文件相关的参数
# --client-ca-file：验证 client (kue-controller-manager、kube-scheduler、kubelet、kube-proxy 等)请求所带的证书
# --enable-bootstrap-token-auth：启用 kubelet bootstrap 的 token 认证
# --requestheader-*：kube-apiserver 的 aggregator layer 相关的配置参数，proxy-client & HPA 需要使用

# --requestheader-client-ca-file：用于签名 --proxy-client-cert-file 和 --proxy-client-key-file 指定的证书；在启用了 metric aggregator 时使用
# 指定的 CA 证书，必须具有 client auth and server auth

# --requestheader-allowed-names：不能为空，值为逗号分割的 --proxy-client-cert-file 证书的 CN 名称，这里设置为 "aggregator"
# 如果不为空，--proxy-client-cert-file 证书的 CN 名称不在 allowed-names 中，则后续查看 node 或 pods 的 metrics 失败

# --service-account-key-file：签名 ServiceAccount Token 的公钥文件，kube-controller-manager 的 --service-account-private-key-file 指定私钥文件，两者配对使用
# --runtime-config=api/all=true： 启用所有版本的 APIs，如 autoscaling/v2alpha1
# --authorization-mode=Node,RBAC、--anonymous-auth=false： 开启 Node 和 RBAC 授权模式，拒绝未授权的请求
# --enable-admission-plugins：启用一些默认关闭的 plugins
# --allow-privileged：运行执行 privileged 权限的容器
# --apiserver-count=3：指定 apiserver 实例的数量
# --event-ttl：指定 events 的保存时间
# --kubelet-*：如果指定，则使用 https 访问 kubelet APIs；需要为证书对应的用户(上面 kubernetes*.pem 证书的用户为 kubernetes) 用户定义 RBAC 规则，否则访问 kubelet API 时提示未授权
# --proxy-client-*：apiserver 访问 metrics-server 使用的证书
# --service-cluster-ip-range： 指定 Service Cluster IP 地址段
# --service-node-port-range： 指定 NodePort 的端口范围

# 如果 kube-apiserver 机器没有运行 kube-proxy，则还需要添加 --enable-aggregator-routing=true 参数
function master::k8s::create-kube-apiserver-service() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee kube-apiserver.service.template <<EOF
  [Unit]
  Description=Kubernetes API Server
  Documentation=https://github.com/GoogleCloudPlatform/kubernetes
  After=network.target

  [Service]
  WorkingDirectory=${K8S_DIR}/kube-apiserver
  ExecStart=/opt/k8s/bin/kube-apiserver \\
    --advertise-address=##NODE_IP## \\
    --default-not-ready-toleration-seconds=360 \\
    --default-unreachable-toleration-seconds=360 \\
    --max-mutating-requests-inflight=2000 \\
    --max-requests-inflight=4000 \\
    --default-watch-cache-size=200 \\
    --delete-collection-workers=2 \\
    --encryption-provider-config=/etc/kubernetes/encryption-config.yaml \\
    --etcd-cafile=/etc/kubernetes/cert/ca.pem \\
    --etcd-certfile=/etc/kubernetes/cert/kubernetes.pem \\
    --etcd-keyfile=/etc/kubernetes/cert/kubernetes-key.pem \\
    --etcd-servers=${ETCD_ENDPOINTS} \\
    --bind-address=##NODE_IP## \\
    --secure-port=6443 \\
    --tls-cert-file=/etc/kubernetes/cert/kubernetes.pem \\
    --tls-private-key-file=/etc/kubernetes/cert/kubernetes-key.pem \\
    --audit-log-maxage=15 \\
    --audit-log-maxbackup=3 \\
    --audit-log-maxsize=100 \\
    --audit-log-truncate-enabled \\
    --audit-log-path=${K8S_DIR}/kube-apiserver/audit.log \\
    --audit-policy-file=/etc/kubernetes/audit-policy.yaml \\
    --profiling \\
    --anonymous-auth=false \\
    --client-ca-file=/etc/kubernetes/cert/ca.pem \\
    --enable-bootstrap-token-auth \\
    --requestheader-allowed-names="aggregator" \\
    --requestheader-client-ca-file=/etc/kubernetes/cert/ca.pem \\
    --requestheader-extra-headers-prefix="X-Remote-Extra-" \\
    --requestheader-group-headers=X-Remote-Group \\
    --requestheader-username-headers=X-Remote-User \\
    --service-account-key-file=/etc/kubernetes/cert/ca.pem \\
    --authorization-mode=Node,RBAC \\
    --runtime-config=api/all=true \\
    --enable-admission-plugins=NodeRestriction \\
    --allow-privileged=true \\
    --apiserver-count=3 \\
    --event-ttl=168h \\
    --kubelet-certificate-authority=/etc/kubernetes/cert/ca.pem \\
    --kubelet-client-certificate=/etc/kubernetes/cert/kubernetes.pem \\
    --kubelet-client-key=/etc/kubernetes/cert/kubernetes-key.pem \\
    --kubelet-timeout=10s \\
    --proxy-client-cert-file=/etc/kubernetes/cert/proxy-client.pem \\
    --proxy-client-key-file=/etc/kubernetes/cert/proxy-client-key.pem \\
    --service-cluster-ip-range=${SERVICE_CIDR} \\
    --service-node-port-range=${NODE_PORT_RANGE} \\
    --service-account-issuer=https://kubernetes.default.svc.cluster.local \\
    --service-account-signing-key-file=/etc/kubernetes/cert/ca-key.pem \\
    --api-audiences=https://kubernetes.default.svc.cluster.local \\
    --v=2
  Restart=on-failure
  RestartSec=10
  Type=notify
  LimitNOFILE=65536

  [Install]
  WantedBy=multi-user.target
EOF
  for (( i=0; i < 3; i++ ))
    do
      sed -e "s/##NODE_NAME##/${NODE_NAMES[i]}/" -e "s/##NODE_IP##/${NODE_IPS[i]}/" kube-apiserver.service.template > kube-apiserver-${NODE_IPS[i]}.service
    done
  ls kube-apiserver*.service

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp kube-apiserver-${node_ip}.service root@${node_ip}:/etc/systemd/system/kube-apiserver.service
    done
}

function master::k8s::kube-apiserver-start() {
  source environment.sh
  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh root@${node_ip} "mkdir -p ${K8S_DIR}/kube-apiserver"
      ssh root@${node_ip} "systemctl daemon-reload && systemctl enable kube-apiserver && systemctl restart kube-apiserver"
    done
}

function master::k8s::kube-apiserver-status() {
  source environment.sh
  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh root@${node_ip} "systemctl status kube-apiserver |grep 'Active:'"
    done
}

function master::k8s::kube-apiserver-log() {
  sudo journalctl -u kube-apiserver
}

function master::k8s::kube-apiserver-info() {
  kubectl cluster-info
  kubectl get all --all-namespaces
#  kubectl get componentstatuses
  kubectl get --raw='/healthz?verbose'
  kubectl get --raw='/readyz?verbose'
  sudo netstat -lnpt|grep kube
}

function master::k8s::kube-controller-manager() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee kube-controller-manager-csr.json <<EOF
  {
      "CN": "system:kube-controller-manager",
      "key": {
          "algo": "rsa",
          "size": 2048
      },
      "hosts": [
        "127.0.0.1",
        "192.168.29.130",
        "192.168.29.131",
        "192.168.29.132"
      ],
      "names": [
        {
          "C": "CN",
          "ST": "ShangHai",
          "L": "ShangHai",
          "O": "system:kube-controller-manager",
          "OU": "superproj"
        }
      ]
  }
EOF
  cfssl gencert -ca=/opt/k8s/work/ca.pem \
    -ca-key=/opt/k8s/work/ca-key.pem \
    -config=/opt/k8s/work/ca-config.json \
    -profile=kubernetes kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager
  ls kube-controller-manager*pem

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp kube-controller-manager*.pem root@${node_ip}:/etc/kubernetes/cert/
    done
}

# 创建分发 kubeconfig
function master::k8s::create-kube-api-config() {
  source environment.sh
  cd /opt/k8s/work

  kubectl config set-cluster kubernetes \
    --certificate-authority=/opt/k8s/work/ca.pem \
    --embed-certs=true \
    --server="https://##NODE_IP##:6443" \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=kube-controller-manager.pem \
    --client-key=kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-context system:kube-controller-manager \
    --cluster=kubernetes \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config use-context system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      sed -e "s/##NODE_IP##/${node_ip}/" kube-controller-manager.kubeconfig > kube-controller-manager-${node_ip}.kubeconfig
      scp kube-controller-manager-${node_ip}.kubeconfig root@${node_ip}:/etc/kubernetes/kube-controller-manager.kubeconfig
    done
}

# 创建 kube-controller-manager.service
# --secure-port=10252、--bind-address=0.0.0.0: 在所有网络接口监听 10252 端口的 https /metrics 请求
# --kubeconfig：指定 kubeconfig 文件路径，kube-controller-manager 使用它连接和验证 kube-apiserver
# --authentication-kubeconfig 和 --authorization-kubeconfig：kube-controller-manager 使用它连接 apiserver，对 client 的请求进行认证和授权。kube-controller-manager 不再使用 --tls-ca-file 对请求 https metrics 的 Client 证书进行校验。如果没有配置这两个 kubeconfig 参数，则 client 连接 kube-controller-manager https 端口的请求会被拒绝(提示权限不足)
# --cluster-signing-*-file：签名 TLS Bootstrap 创建的证书
# --root-ca-file：放置到容器 ServiceAccount 中的 CA 证书，用来对 kube-apiserver 的证书进行校验
# --service-account-private-key-file：签名 ServiceAccount 中 Token 的私钥文件，必须和 kube-apiserver 的 --service-account-key-file 指定的公钥文件配对使用
# --service-cluster-ip-range：指定 Service Cluster IP 网段，必须和 kube-apiserver 中的同名参数一致
# --leader-elect=true：集群运行模式，启用选举功能；被选为 leader 的节点负责处理工作，其它节点为阻塞状态
# --controllers=*,bootstrapsigner,tokencleaner：启用的控制器列表，tokencleaner 用于自动清理过期的 Bootstrap token
# --horizontal-pod-autoscaler-*：custom metrics 相关参数，支持 autoscaling/v2alpha1
# --tls-cert-file、--tls-private-key-file：使用 https 输出 metrics 时使用的 Server 证书和秘钥
# --use-service-account-credentials=true: kube-controller-manager 中各 controller 使用 serviceaccount 访问 kube-apiserver
function master::k8s::create-kube-controller-manager-service() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee kube-controller-manager.service.template <<EOF
  [Unit]
  Description=Kubernetes Controller Manager
  Documentation=https://github.com/GoogleCloudPlatform/kubernetes

  [Service]
  WorkingDirectory=${K8S_DIR}/kube-controller-manager
  ExecStart=/opt/k8s/bin/kube-controller-manager \\
    --profiling \\
    --cluster-name=kubernetes \\
    --controllers=*,bootstrapsigner,tokencleaner \\
    --kube-api-qps=1000 \\
    --kube-api-burst=2000 \\
    --leader-elect \\
    --use-service-account-credentials\\
    --concurrent-service-syncs=2 \\
    --bind-address=##NODE_IP## \\
    --secure-port=10252 \\
    --tls-cert-file=/etc/kubernetes/cert/kube-controller-manager.pem \\
    --tls-private-key-file=/etc/kubernetes/cert/kube-controller-manager-key.pem \\
    --authentication-kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig \\
    --client-ca-file=/etc/kubernetes/cert/ca.pem \\
    --requestheader-allowed-names="aggregator" \\
    --requestheader-client-ca-file=/etc/kubernetes/cert/ca.pem \\
    --requestheader-extra-headers-prefix="X-Remote-Extra-" \\
    --requestheader-group-headers=X-Remote-Group \\
    --requestheader-username-headers=X-Remote-User \\
    --authorization-kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig \\
    --cluster-signing-cert-file=/etc/kubernetes/cert/ca.pem \\
    --cluster-signing-key-file=/etc/kubernetes/cert/ca-key.pem \\
    --horizontal-pod-autoscaler-sync-period=10s \\
    --concurrent-deployment-syncs=10 \\
    --concurrent-gc-syncs=30 \\
    --node-cidr-mask-size=24 \\
    --service-cluster-ip-range=${SERVICE_CIDR} \\
    --terminated-pod-gc-threshold=10000 \\
    --root-ca-file=/etc/kubernetes/cert/ca.pem \\
    --service-account-private-key-file=/etc/kubernetes/cert/ca-key.pem \\
    --kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig \\
    --v=2
  Restart=on-failure
  RestartSec=5

  [Install]
  WantedBy=multi-user.target
EOF
  for (( i=0; i < 3; i++ ))
    do
      sed -e "s/##NODE_NAME##/${NODE_NAMES[i]}/" -e "s/##NODE_IP##/${NODE_IPS[i]}/" kube-controller-manager.service.template > kube-controller-manager-${NODE_IPS[i]}.service
    done
  ls kube-controller-manager*.service

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp kube-controller-manager-${node_ip}.service root@${node_ip}:/etc/systemd/system/kube-controller-manager.service
    done
}

function master::k8s::kube-controller-manager-start() {
  source environment.sh

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh root@${node_ip} "mkdir -p ${K8S_DIR}/kube-controller-manager"
      ssh root@${node_ip} "systemctl daemon-reload && systemctl enable kube-controller-manager && systemctl restart kube-controller-manager"
    done
}

function master::k8s::kube-controller-manager-status() {
  source environment.sh

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh root@${node_ip} "systemctl status kube-controller-manager|grep Active"
    done
}

function master::k8s::kube-controller-manager-log() {
  journalctl -u kube-controller-manager
}

# 查看输出的 metrics
function master::k8s::kube-controller-manager-metrics::info() {
  source environment.sh
  curl -s --cacert /opt/k8s/work/ca.pem --cert /opt/k8s/work/admin.pem --key /opt/k8s/work/admin-key.pem https://${NODE_IPS[0]}:10252/metrics |head
}

function master::k8s::kube-controller-manager-leader() {
  kubectl -n kube-system get leases kube-controller-manager
}

function master::k8s::kube-scheduler() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee kube-scheduler-csr.json <<EOF
  {
      "CN": "system:kube-scheduler",
      "hosts": [
        "127.0.0.1",
        "192.168.29.130",
        "192.168.29.131",
        "192.168.29.132"
      ],
      "key": {
          "algo": "rsa",
          "size": 2048
      },
      "names": [
        {
          "C": "CN",
          "ST": "ShangHai",
          "L": "ShangHai",
          "O": "system:kube-scheduler",
          "OU": "superproj"
        }
      ]
  }
EOF
  cfssl gencert -ca=/opt/k8s/work/ca.pem \
    -ca-key=/opt/k8s/work/ca-key.pem \
    -config=/opt/k8s/work/ca-config.json \
    -profile=kubernetes kube-scheduler-csr.json | cfssljson -bare kube-scheduler
  ls kube-scheduler*pem
  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp kube-scheduler*.pem root@${node_ip}:/etc/kubernetes/cert/
    done
}

function master::k8s::create-kube-scheduler-config () {
  source environment.sh
  cd /opt/k8s/work

  kubectl config set-cluster kubernetes \
    --certificate-authority=/opt/k8s/work/ca.pem \
    --embed-certs=true \
    --server="https://##NODE_IP##:6443" \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=kube-scheduler.pem \
    --client-key=kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-context system:kube-scheduler \
    --cluster=kubernetes \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config use-context system:kube-scheduler --kubeconfig=kube-scheduler.kubeconfig

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      sed -e "s/##NODE_IP##/${node_ip}/" kube-scheduler.kubeconfig > kube-scheduler-${node_ip}.kubeconfig
      scp kube-scheduler-${node_ip}.kubeconfig root@${node_ip}:/etc/kubernetes/kube-scheduler.kubeconfig
    done
}

function master::k8s::create-kube-scheduler-yaml() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee kube-scheduler.yaml.template <<EOF
  apiVersion: kubescheduler.config.k8s.io/v1
  kind: KubeSchedulerConfiguration
  clientConnection:
    burst: 200
    kubeconfig: "/etc/kubernetes/kube-scheduler.kubeconfig"
    qps: 100
  enableContentionProfiling: false
  enableProfiling: true
  leaderElection:
    leaderElect: true
EOF
  for (( i=0; i < 3; i++ ))
    do
      sed -e "s/##NODE_NAME##/${NODE_NAMES[i]}/" -e "s/##NODE_IP##/${NODE_IPS[i]}/" kube-scheduler.yaml.template > kube-scheduler-${NODE_IPS[i]}.yaml
    done
  ls kube-scheduler*.yaml

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp kube-scheduler-${node_ip}.yaml root@${node_ip}:/etc/kubernetes/kube-scheduler.yaml
    done
}

function master::k8s::create-kube-scheduler-service() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee kube-scheduler.service.template <<EOF
  [Unit]
  Description=Kubernetes Scheduler
  Documentation=https://github.com/GoogleCloudPlatform/kubernetes

  [Service]
  WorkingDirectory=${K8S_DIR}/kube-scheduler
  ExecStart=/opt/k8s/bin/kube-scheduler \\
    --config=/etc/kubernetes/kube-scheduler.yaml \\
    --bind-address=##NODE_IP## \\
    --secure-port=10259 \\
    --tls-cert-file=/etc/kubernetes/cert/kube-scheduler.pem \\
    --tls-private-key-file=/etc/kubernetes/cert/kube-scheduler-key.pem \\
    --authentication-kubeconfig=/etc/kubernetes/kube-scheduler.kubeconfig \\
    --client-ca-file=/etc/kubernetes/cert/ca.pem \\
    --requestheader-allowed-names="" \\
    --requestheader-client-ca-file=/etc/kubernetes/cert/ca.pem \\
    --requestheader-extra-headers-prefix="X-Remote-Extra-" \\
    --requestheader-group-headers=X-Remote-Group \\
    --requestheader-username-headers=X-Remote-User \\
    --authorization-kubeconfig=/etc/kubernetes/kube-scheduler.kubeconfig \\
    --v=2
  Restart=always
  RestartSec=5
  StartLimitInterval=0

  [Install]
  WantedBy=multi-user.target
EOF
  for (( i=0; i < 3; i++ ))
    do
      sed -e "s/##NODE_NAME##/${NODE_NAMES[i]}/" -e "s/##NODE_IP##/${NODE_IPS[i]}/" kube-scheduler.service.template > kube-scheduler-${NODE_IPS[i]}.service
    done
  ls kube-scheduler*.service

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp kube-scheduler-${node_ip}.service root@${node_ip}:/etc/systemd/system/kube-scheduler.service
    done
}

function master::k8s::kube-scheduler-start() {
  source environment.sh
  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh root@${node_ip} "mkdir -p ${K8S_DIR}/kube-scheduler"
      ssh root@${node_ip} "systemctl daemon-reload && systemctl enable kube-scheduler && systemctl restart kube-scheduler"
    done
}

function master::k8s::kube-scheduler-status() {
  source environment.sh

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh root@${node_ip} "systemctl status kube-scheduler|grep Active"
    done
}

function master::k8s::kube-scheduler-log() {
  journalctl -u kube-scheduler
}

function master::k8s::kube-scheduler::metrics::info () {
  source environment.sh
  sudo netstat -lnpt |grep kube-sch

  curl -s --cacert /opt/k8s/work/ca.pem --cert /opt/k8s/work/admin.pem --key /opt/k8s/work/admin-key.pem https://${NODE_IPS[0]}:10259/metrics |head
}

function master::k8s::kube-scheduler::leader() {
  kubectl -n kube-system get leases kube-scheduler
}