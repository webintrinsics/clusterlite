#!/usr/bin/env bash

#
# License: https://github.com/cadeworks/cade/blob/master/LICENSE
#

# Prerequisites:
# - Ubuntu 16.04 machine (or another Linux with installed docker 1.13.1)
#   with valid hostname, IP interface, DNS, proxy, apt-get configuration
# - Internet connection

set -e

DIR="$( cd "$( dirname "$0" )" && pwd )" # get current file directory

${DIR}/run-package.sh

line=$(head -26 ${DIR}/cade.sh | grep version_system)
version=${line/version_system=/}
echo ${version} > ${DIR}/version.txt
rm -Rf ${DIR}/target/universal/cade
unzip -o ${DIR}/target/universal/cade-${version}.zip -d ${DIR}/target/universal/
line=$(head -26 ${DIR}/cade.sh | grep version_terraform)
terraform_version=${line/version_terraform=/}
if [ ! -f ${DIR}/deps/terraform-${terraform_version} ];
then
    wget -O /tmp/terraform_${terraform_version}_linux_amd64.zip \
        https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip
    unzip -o /tmp/terraform_${terraform_version}_linux_amd64.zip -d ${DIR}/deps/
    mv ${DIR}/deps/terraform ${DIR}/deps/terraform-${terraform_version}
fi
cp ${DIR}/deps/terraform-${terraform_version} ${DIR}/deps/terraform
docker build -t cadeworks/system:${version} ${DIR}
rm ${DIR}/deps/terraform

# build etcd
line=$(head -26 ${DIR}/cade.sh | grep version_etcd)
etcd_version=${line/version_etcd=/}
echo ${etcd_version} > ${DIR}/deps/etcd/files/version.txt
docker build -t cadeworks/etcd:${etcd_version} ${DIR}/deps/etcd

# build weave
line=$(head -26 ${DIR}/cade.sh | grep version_weave)
weave_version=${line/version_weave=/}
echo ${weave_version} > ${DIR}/deps/weave/files/version.txt
docker build -t cadeworks/weave:${weave_version} ${DIR}/deps/weave

# build proxy
line=$(head -26 ${DIR}/cade.sh | grep version_proxy)
proxy_version=${line/version_proxy=/}
echo ${proxy_version} > ${DIR}/deps/proxy/files/version.txt
docker build -t cadeworks/proxy:${proxy_version} ${DIR}/deps/proxy

if [[ ! -z $1 ]];
then
    # ensure docker hub credetials
    if [ "$(cat ~/.docker/config.json | grep auth\" | wc -l)" -eq "0" -a "$(uname -o)" != "Msys" ]
    then
      docker login
    fi

    docker push cadeworks/system:${version}
    docker push cadeworks/etcd:${etcd_version}
    docker push cadeworks/weave:${weave_version}
    docker push cadeworks/proxy:${proxy_version}
else
    echo "skipping docker push, because the script was invoked without arguments"
fi
