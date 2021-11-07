#!/bin/bash
# ******************************************************
# Author       	:	serialt
# Email        	:	serialt@qq.com
# Filename     	:	go_install.sh
# Version      	:	v1.0
# Created Time 	:	2020-09-20 19:53
# Last modified	:	2020-09-21 00:29
# By Modified  	:
# Description  	:   install go env
#
# ******************************************************

GO_INSTALL_PATH='/usr/local'
GO_FILe_PATH='/usr/local/src'
GO_FILE_url='https://studygolang.com/dl/golang'
GO_FILe_name='go1.17.3.linux-amd64.tar.gz'

set -eu
set -o pipefail

downloadGoFile() {
    [ -f ${GO_FILe_PATH}/${GO_FILe_name} ] && rm -rf ${GO_FILe_PATH}/${GO_FILe_name}
    which wget &>/dev/nul
    [ $? != 0 ] && yum -y install wget
    wget -O ${GO_FILe_PATH}/${GO_FILe_name} ${GO_FILE_url}/${GO_FILe_name}
}

installGo() {
    echo "installGO"
    [ -f ${GO_INSTALL_PATH}/go ] && rm -rf ${GO_INSTALL_PATH}/go
    tar -xf ${GO_FILe_PATH}/${GO_FILe_name} -C ${GO_INSTALL_PATH}
}

configGo() {
    cat >/etc/profile.d/go.sh <<EOF
export GOROOT=${GO_INSTALL_PATH}/go
#GOPROXY=https://mirrors.aliyun.com/goproxy/
export GOPROXY=https://goproxy.cn,direct
export GOPATH=/root/go
export GO111MODULE="on"
#export GO111MODULE="on"
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOROOT/bin:$GOBIN
EOF
}

main() {
    downloadGoFile
    installGo
    configGo
    source /etc/profile.d/go.sh
}

main
