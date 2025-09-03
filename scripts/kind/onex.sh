function onex::install {
  git clone https://github.com/pachirode/onex.git
  cd onex

  HOSTIP=`ip -o -4 addr show $1 | awk '{split($4, a, "/"); print a[1]}'`
  sed "s/apiServerAddress.*/apiServerAddress: ${HOSTIP}/g" manifests/installation/kubernetes/kind-onex.yaml > /tmp/kind-onex.yaml
  kind create cluster --config=/tmp/kind-onex.yaml
}

function onex::kind::status() {
  kind get clusters
  kubectl -n kube-system get pods --no-headers | grep -v Running
  # 查看节点
  kubectl get nodes
}

# 访问集群  kubectl cluster-info 来访问新建的 Kind 集群，以验证集群成功创建
function onex::kind::create() {
  kubectl config use-context kind-onex
  kubectl cluster-info --context kind-onex
}

function onex::install::storage() {
  cd onex

  kubectl create secret generic mariadb --from-literal=MYSQL_ROOT_PASSWORD='onex(#)666' --from-literal=MYSQL_DATABASE=onex --from-literal=MYSQL_USER=onex --from-literal=MYSQL_PASSWORD='onex(#)666'
  kubectl -n infra apply -f manifests/installation/storage/mariadb
}