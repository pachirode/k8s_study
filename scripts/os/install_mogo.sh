function install::mongosh() {
  curl -Lo mongosh_2.5.7.tgz https://downloads.mongodb.com/compass/mongosh-2.5.7-linux-x64.tgz
  tar -xvzf mongosh_2.5.7.tgz
#  cp mongosh-2.5.7-linux-x64/bin/mongosh* /usr/local/bin
}