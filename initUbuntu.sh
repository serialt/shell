#!/bin/bash
# ******************************************************
# Author       	:	serialt 
# Email        	:	serialt@qq.com
# Filename     	:	initUbuntu.sh
# Version      	:	v1.0
# Created Time 	:	2020-07-05 05:47
# Last modified	:	2020-07-05 05:47
# By Modified  	: 
# Description  	:       init centos7 system
#  
# ******************************************************

set -eu
set -o pipefail



function changeAptSource {
echo "更换apt源为华为源"
cp -a /etc/apt/sources.list /etc/apt/sources.list.bak
sed -i "s@http://.*archive.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list
sed -i "s@http://.*security.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list
apt-get update
}

function updateAptPkgs {
echo "升级全部包"
apt-get upgrade -y
}

function installDockerCompose { 
apt install docker-compose -y

}

function installDocker {
curl -fsSL https://repo.huaweicloud.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://repo.huaweicloud.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
apt update && apt install docker-ce -y
cat > /etc/docker/daemon.json<<EOF
{
  "data-root": "/var/lib/docker",
  "insecure-registries" : ["repo.imau.com"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "registry-mirrors": [
      "https://w9tu3nny.mirror.aliyuncs.com",
      "https://0648c427d18026450f2dc01eb3f5fa00.mirror.swr.myhuaweicloud.com",
      "http://hub-mirror.c.163.com",
      "https://docker.mirrors.ustc.edu.cn",
      "https://registry.docker-cn.com"      
      ],
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF
systemctl enable docker
systemctl restart docker
}

function createSwap {
echo "创建swap分区"
[[ -f /swapfile ]] && return
free -h
fallocate -l 2G /swapfile
ls -lh /swapfile
chmod 600 /swapfile
ls -lh /swapfile
mkswap /swapfile
swapon /swapfile
swapon --show
cp /etc/fstab{,.ori}
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
cat /etc/fstab
cat /proc/sys/vm/swappiness
sysctl vm.swappiness=10
cp /etc/sysctl.conf{,.ori}
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sysctl -p
}

function installEssential {
apt-get install -y unzip nfs-common python3-dev python3-venv redis-tools postgresql-client-10
sed -i '17s/false/true/' /etc/cloud/cloud.cfg
}

function configPip {
[ -f /etc/pip.conf ] && return
echo "配置pip"
cat >/etc/pip.conf<<EOF
[global]
index-url = https://repo.huaweicloud.com/repository/pypi/simple
trusted-host = repo.huaweicloud.com
timeout = 120
EOF
}

function configNTP {
timedatectl set-timezone Asia/Shanghai
timedatectl set-ntp yes
timedatectl set-local-rtc no
timedatectl status
}

function MAIN {
changeAptSource && updateAptPkgs
createSwap
installEssential
installDocker
installDockerCompose
configPip
configNTP
}

MAIN
