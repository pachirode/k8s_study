function install::common() {
  sudo apt-get update && sudo apt-get install -y \
    make autoconf automake cmake \
    perl libcurl4-openssl-dev libtool \
    gcc g++ libc6-dev zlib1g-dev \
    git-lfs telnet lrzsz jq \
    libexpat1-dev libssl-dev \
    fzf neovim git
}