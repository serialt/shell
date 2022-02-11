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
    cat >/etc/docker/daemon.json <<EOF
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


function installEssential {
    apt-get install -y unzip python3-dev python3-venv postgresql-client-10
    # 保护重启后hostname不发生变化
    sed -i '17s/false/true/' /etc/cloud/cloud.cfg
}

function configPip {
    [ -f /etc/pip.conf ] && return
    echo "配置pip"
    cat >/etc/pip.conf <<EOF
[global]
index-url = https://repo.huaweicloud.com/repository/pypi/simple
trusted-host = repo.huaweicloud.com
timeout = 120
EOF
}

function history(){
	if ! grep "HISTTIMEFORMAT" /etc/profile >/dev/null 2>&1
	then 
        cat >> /etc/profile <<EOF
UserIP=$(who -u am i | cut -d"("  -f 2 | sed -e "s/[()]//g")
export HISTTIMEFORMAT="[%F %T] [`whoami`] [${UserIP}] " 
EOF
	fi
	sed -i "s/HISTSIZE=1000/HISTSIZE=999999999/" /etc/profile
}


function Fail2ban(){
    cat >/etc/motd <<EOF

        Welcome to IMAU

EOF
    apt install -y fail2ban
    cat >> /etc/fail2ban/jail.conf <<EOF
[sshd]
port    = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
EOF
    systemctl restart fail2ban
    systemctl enable fail2ban
    
}

function configNTP {
    timedatectl set-timezone Asia/Shanghai
    timedatectl set-ntp yes
    timedatectl set-local-rtc no
    timedatectl status
}

function MAIN {
    changeAptSource && updateAptPkgs
    installEssential
    installDocker
    installDockerCompose
    configPip
    configNTP
}

MAIN
