function master::install::etcl() {
  source environment.sh
  cd /opt/k8s/work

  export https_proxy=http://192.168.1.6:7890
  sudo -E wget https://github.com/etcd-io/etcd/releases/download/v3.5.22/etcd-v3.5.22-linux-amd64.tar.gz
  tar -xvf etcd-v3.5.22-linux-amd64.tar.gz
#  sudo mv etcd-v3.5.22-linux-amd64/etcd* /opt/k8s/bin/

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp etcd-v3.5.22-linux-amd64/etcd* root@${node_ip}:/opt/k8s/bin
      ssh root@${node_ip} "chmod +x /opt/k8s/bin/*"
    done
}

# 创建 Etcd 证书和私钥
function master::etcd::etcd-csr() {
  source environment.sh
  cd /opt/k8s/work
  sudo tee etcd-csr.json <<EOF
  {
    "CN": "etcd",
    "hosts": [
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
        "O": "k8s",
        "OU": "superproj"
      }
    ]
  }
EOF
  cfssl gencert -ca=/opt/k8s/work/ca.pem \
      -ca-key=/opt/k8s/work/ca-key.pem \
      -config=/opt/k8s/work/ca-config.json \
      -profile=kubernetes etcd-csr.json | cfssljson -bare etcd
  ls etcd*pem

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh root@${node_ip} "mkdir -p /etc/etcd/cert"
      scp etcd*.pem root@${node_ip}:/etc/etcd/cert/
    done
}

# 创建 Etcd 服务模板
# WorkingDirectory、--data-dir：指定工作目录和数据目录，需要在启动服务之前创建
# -wal-dir：指定 wal 目录，为了提高性能，一般使用 SSD 或者和 --data-dir 不同的磁盘
# --name：指定节点名称，当 --initial-cluster-state 值为 new 时，--name 的参数值必须位于 --initial-cluster 列表中
# --cert-file、--key-file：etcd server 与 client 通信时使用的证书和私钥
# --trusted-ca-file：签名 client 证书的 CA 证书，用于验证 client 证书
# --peer-cert-file、--peer-key-file：etcd 与 peer 通信使用的证书和私钥
# --peer-trusted-ca-file：签名 peer 证书的 CA 证书，用于验证 peer 证书
function master::etcd::template() {
  source environment.sh
  cd /opt/k8s/work

  sudo tee etcd.service.template <<EOF
  [Unit]
  Description=Etcd Server
  After=network.target
  After=network-online.target
  Wants=network-online.target
  Documentation=https://github.com/coreos

  [Service]
  Type=notify
  WorkingDirectory=${ETCD_DATA_DIR}
  ExecStart=/opt/k8s/bin/etcd \\
    --data-dir=${ETCD_DATA_DIR} \\
    --wal-dir=${ETCD_WAL_DIR} \\
    --name=##NODE_NAME## \\
    --cert-file=/etc/etcd/cert/etcd.pem \\
    --key-file=/etc/etcd/cert/etcd-key.pem \\
    --trusted-ca-file=/etc/kubernetes/cert/ca.pem \\
    --peer-cert-file=/etc/etcd/cert/etcd.pem \\
    --peer-key-file=/etc/etcd/cert/etcd-key.pem \\
    --peer-trusted-ca-file=/etc/kubernetes/cert/ca.pem \\
    --peer-client-cert-auth \\
    --client-cert-auth \\
    --listen-peer-urls=https://##NODE_IP##:2380 \\
    --initial-advertise-peer-urls=https://##NODE_IP##:2380 \\
    --listen-client-urls=https://##NODE_IP##:2379,http://127.0.0.1:2379 \\
    --advertise-client-urls=https://##NODE_IP##:2379 \\
    --initial-cluster-token=etcd-cluster-0 \\
    --initial-cluster=${ETCD_NODES} \\
    --initial-cluster-state=new \\
    --auto-compaction-mode=periodic \\
    --auto-compaction-retention=1 \\
    --max-request-bytes=33554432 \\
    --quota-backend-bytes=6442450944 \\
    --heartbeat-interval=250 \\
    --election-timeout=2000
  Restart=on-failure
  RestartSec=5
  LimitNOFILE=65536

  [Install]
  WantedBy=multi-user.target
EOF
  for (( i=0; i < 3; i++ ))
    do
      sed -e "s/##NODE_NAME##/${NODE_NAMES[i]}/" -e "s/##NODE_IP##/${NODE_IPS[i]}/" etcd.service.template > etcd-${NODE_IPS[i]}.service
    done
  ls *.service

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      scp etcd-${node_ip}.service root@${node_ip}:/etc/systemd/system/etcd.service
    done
}

function master::etcd::start() {
  source environment.sh

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh root@${node_ip} "mkdir -p ${ETCD_DATA_DIR} ${ETCD_WAL_DIR}"
      ssh root@${node_ip} "systemctl daemon-reload && systemctl enable etcd && systemctl restart etcd " &
    done
}

function master::etcd::status() {
  source environment.sh

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh root@${node_ip} "systemctl status etcd|grep Active"
    done
}

function master::etcd::log() {
  sudo journalctl -u etcd
}

function master::etcd::verify() {
  source environment.sh

  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      sudo /opt/k8s/bin/etcdctl \
      --endpoints=https://${node_ip}:2379 \
      --cacert=/etc/kubernetes/cert/ca.pem \
      --cert=/etc/etcd/cert/etcd.pem \
      --key=/etc/etcd/cert/etcd-key.pem endpoint health
    done
}

function master::etcd::leader() {
  source environment.sh
  sudo /opt/k8s/bin/etcdctl \
         -w table --cacert=/etc/kubernetes/cert/ca.pem \
         --cert=/etc/etcd/cert/etcd.pem \
         --key=/etc/etcd/cert/etcd-key.pem \
         --endpoints=${ETCD_ENDPOINTS} endpoint status
}