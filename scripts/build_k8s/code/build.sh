sudo apt update
sudo apt install build-essential
sudo apt install rsync # 文件同步和传输工具
sudo apt install jq # 命令行 Json 处理器

wget 'https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-453.0.0-linux-x86_64.tar.gz?hl=zh-cn' -O google-cloud-cli-453.0.0-linux-x86_64.tar.gz
tar -xvzf google-cloud-cli-453.0.0-linux-x86_64.tar.gz
./google-cloud-sdk/install.sh

sudo apt install -y python3-pip
sudo pip3 install pyyaml # 部分测试用例使用了 PyYAML

# 安装 Etcd
./hack/install_etcd.sh
export PATH="$GOPATH/src/k8s.io/kubernetes/third_party/etcd:${PATH}"

# 编译指定的 kubernetes 组件