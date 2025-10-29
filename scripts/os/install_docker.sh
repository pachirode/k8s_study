function install::docker() {
  sudo apt-get update
  sudo apt-get install ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update

  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

function docker::images() {
  sudo tee /etc/docker/daemon.json <<EOF
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "insecure-registries": [],
    "live-restore": true,
    "bip": "172.16.0.1/24",
    "storage-driver": "overlay2",
    "registry-mirrors": [
        "https://registry.docker-cn.com",
        "https://docker.mirrors.ustc.edu.cn",
        "https://hub-mirror.c.163.com",
        "https://mirror.baidubce.com",
        "https://ccr.ccs.tencentyun.com"
    ],
    "data-root": "/data/lib/docker",
        "log-driver": "json-file",
        "dns": [],
        "default-runtime": "runc",
        "log-opts": {
          "max-size": "100m",
          "max-file": "10"
    }
}
EOF
#    添加本地私有仓库，内网访问使用 http 协议
#    "insecure-registries": [
#        "192.168.1.6"
#    ]

  sudo mkdir -p /etc/systemd/system/docker.service.d
  sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=http://192.168.1.6:7890"
Environment="HTTPS_PROXY=http://192.168.1.6:7890"
Environment="NO_PROXY=localhost,127.0.0.1"
EOF

  sudo systemctl daemon-reload
  sudo systemctl restart docker

  docker info
  sudo -i groupadd docker
  sudo usermod -aG docker $USER
#  newgrp docker # 或者重启会话
  sudo systemctl enable docker.service
  sudo systemctl enable containerd.service
}