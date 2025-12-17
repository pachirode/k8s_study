sudo apt update
sudo apt install -y curl ca-certificates gnupg

curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version