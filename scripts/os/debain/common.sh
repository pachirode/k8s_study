function install::common() {
  sudo apt-get update && sudo apt-get install -y \
    make autoconf automake cmake \
    perl libcurl4-openssl-dev libtool \
    gcc g++ libc6-dev zlib1g-dev \
    git-lfs telnet lrzsz jq \
    libexpat1-dev libssl-dev \
    fzf neovim git zsh \
    mariadb-client redis-tools
}

function install::neovim() {
  url = $(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | jq -r '.assets[] | select(.name | test("linux-x86_64.tar")) | .browser_download_url')
  curl -L -o nvim-x86_64.tar.gz "$url"
  tar -zxvf nvim-x86_64.tar.gz

  sudo apt install make gcc ripgrep unzip git xclip curl
}
