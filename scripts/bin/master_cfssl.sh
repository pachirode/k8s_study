function master::install::cfssl() {
  sudo mkdir -p /opt/k8s/cert && cd /opt/k8s/work

  export https_proxy=http://192.168.1.6:7890

  sudo -E wget https://github.com/cloudflare/cfssl/releases/download/v1.6.5/cfssl_1.6.5_linux_amd64
  sudo mv cfssl_1.6.5_linux_amd64 /opt/k8s/bin/cfssl

  sudo -E wget https://github.com/cloudflare/cfssl/releases/download/v1.6.5/cfssljson_1.6.5_linux_amd64
  sudo mv cfssljson_1.6.5_linux_amd64 /opt/k8s/bin/cfssljson

  sudo -E wget https://github.com/cloudflare/cfssl/releases/download/v1.6.5/cfssl-certinfo_1.6.5_linux_amd64
  sudo mv cfssl-certinfo_1.6.5_linux_amd64 /opt/k8s/bin/cfssl-certinfo

  sudo chmod +x /opt/k8s/bin/*
  source $HOME/.bashrc
}

# 创建配置文件，用于根证书使用场景和具体参数
# signing: 根证书的签名配置
# server auth: client 可以使用该证书对 server 提供证书校验
# client auth: server 可以使用该证书对 client 提供证书校验
# expiry；证书有效期限
function master::cfssl::ca-config() {
  cd /opt/k8s/work
  sudo tee ca-config.json <<EOF
  {
    "signing": {
      "default": {
        "expiry": "87600h"
      },
      "profiles": {
        "kubernetes": {
          "usages": [
              "signing",
              "key encipherment",
              "server auth",
              "client auth"
          ],
          "expiry": "876000h"
        }
      }
    }
  }
EOF
}

# 创建证书签名请求文件
# CN: 证书的公用名; kube-apiserver 从证书提取该字段作为请求用户名，浏览器使用该字段验证网站是否合法
# O: 证书的机构； kube-apiserver 从证书中提取该字段作为请求用户所属的组
# kube-apiserver 将提取 User, Group 作为 RBAC 授权的用户标识
# 不同证书的 CN、C、ST、L、O、OU 组合必须不同，否则可能出现 PEER'S CERTIFICATE HAS AN INVALID SIGNATURE 错误
function master::cfssl::ca-csr() {
  cd /opt/k8s/work
  sudo tee ca-csr.json <<EOF
  {
    "CN": "kubernetes-ca",
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
    ],
    "ca": {
      "expiry": "876000h"
    }
  }
EOF
}

function master::cfssl::create-cert() {
  cd /opt/k8s/work
  sudo chown -R $(whoami) /opt/k8s/work

  cfssl gencert -initca ca-csr.json | cfssljson -bare ca
  ls ca*
}

function master::cfssl::scp() {
  source environment.sh
  cd /opt/k8s/work
  for node_ip in ${NODE_IPS[@]}
    do
      echo ">>> ${node_ip}"
      ssh root@${node_ip} "mkdir -p /etc/kubernetes/cert"
      scp ca*.pem ca-config.json root@${node_ip}:/etc/kubernetes/cert
    done
}