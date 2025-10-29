# Harbor

一个开源的容器镜像注册中心，主要用来管理和存储 `Docker` 镜像

### 安装

##### SSL

```bash
mkdir /data/ssl -p
cd /data/ssl
openssl genrsa -out ca.key 3072
openssl req -x509 -new -nodes -days 3650 -key ca.key -out ca.pem -subj "/CN=Harbor Root CA"
openssl genrsa -out harbor.key 3072
openssl req -new -key harbor.key -out harbor.csr -subj "/CN=Harbor Root CA"

openssl x509 -req -in harbor.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out harbor.pem -days 3650
```

##### 关闭 SELinux

##### 配置时间同步

##### 安装

```bash
# 下载软件包
curl -L -o harbor-latest.tgz $(curl -s https://api.github.com/repos/goharbor/harbor/releases/latest \
  | grep "browser_download_url" \
  | cut -d '"' -f 4 \
  | grep '\.tgz$' \
  | head -n 1)
  
tar -zxvf harbor-latest.tgz -C /opt
mkdir -p /opt/harbor/certs
mkdir -p /opt/harbor/data

# 复制并修改配置
cp harbor.yml.tmpl harbor.yml

# 会自动拉取相关镜像
./install.sh
```
> 默认 `harbor` 账号密码：`admin/Harbor12345`
> 使用私有仓库需要先 docker login 

##### 使用

```bash
docker login 192.168.29.130
docker tag mariadb:11.2.2 192.168.29.130/test/mariadb:11.2.2
docker push 192.168.29.130/test/mariadb:11.2.2
```