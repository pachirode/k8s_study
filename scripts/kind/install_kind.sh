function install::kind() {
  [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.19.0/kind-linux-amd64
#  [ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.19.0/kind-linux-arm64

  chmod +x ./kind
  mkdir -p $HOME/bin
  mv kind $HOME/bin
  kind completion bash > ${HOME}/.kind-completion.bash # 配置 kind bash 自动补全
}