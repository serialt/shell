#!/bin/bash
# ******************************************************
# Author       	:	serialt
# Email        	:	serialt@qq.com
# Filename     	:	centos8_init.sh
# Version      	:	v1.0
# Created Time 	:	2020-07-05 05:47
# Last modified	:	2020-07-05 05:47
# By Modified  	:
# Description  	:       init centos8 system
#
# ******************************************************

### before
set -u

# huawei,aliyun,tsinghua,bfsu,ustc,tencent,163,zju
getUrl() {
    url=$1
    case $url in
    'huawei')
        echo "https://repo.huaweicloud.com"
        ;;
    'aliyun')
        echo "https://mirrors.aliyun.com"
        ;;
    'tsinghua')
        echo "https://mirrors.tuna.tsinghua.edu.cn"
        ;;
    'bfsu')
        echo "https://mirrors.bfsu.edu.cn"
        ;;
    'ustc')
        echo "http://mirrors.ustc.edu.cn"
        ;;
    'tencent')
        echo "https://mirrors.cloud.tencent.com"
        ;;
    '163')
        echo "http://mirrors.163.com"
        ;;
    'zju')
        echo "http://mirrors.zju.edu.cn"
        ;;
    *)
        echo "输入有误，无法识别"
        ;;

    esac
}

stopFirewalld() {
    # stop and disable firewalld
    systemctl stop firewalld
    systemctl disable firewalld

    # stop and disable selinux
    local selinux_mode=$(grep '^SELINUX=' /etc/selinux/config | awk -F'=' '{print $2}')
    if [ ${selinux_mode} != "disabled" ]; then
        setenforce 0
        sed -i '/^SELINUX=/c SELINUX=disabled' /etc/selinux/config
    fi
}

chronydTime() {
    ### chronyd 时间同步
    timedatectl set-timezone "Asia/Shanghai"
    yum -y install chrony
    systemctl restart chronyd
    systemctl enable chronyd
}

installBaseRPM() {
    ### install the  base sofeware on centos7
    yum -y install bash-completion vim-enhanced net-tools ntp lrzsz lftp wget

}

configYUM() {
    ### 安装华为yum和epel源
    # base
    curl -o /etc/yum.repos.d/CentOS-Base.repo https://repo.huaweicloud.com/repository/conf/CentOS-8-reg.repo
    # epel
    rpm -qa | grep epel-release &>/dev/null
    [ $? -ne 0 ] && yum -y remove epel-release
    yum -y install epel-release
    sed -i "s/#baseurl/baseurl/g" /etc/yum.repos.d/epel.repo
    sed -i "s/metalink/#metalink/g" /etc/yum.repos.d/epel.repo
    sed -i "s@https\?://download.fedoraproject.org/pub@https://repo.huaweicloud.com@g" /etc/yum.repos.d/epel.repo
}

# centos8支持多个版本的python2, python36, python38
configPython3() {
    yum -y install python36
    [ -f /etc/pip.conf ] && return
    echo "配置pip"
    cat >/etc/pip.conf <<EOF
[global]
index-url = https://repo.huaweicloud.com/repository/pypi/simple
trusted-host = repo.huaweicloud.com
timeout = 120
EOF

}

main() {
    stopFirewalld
    chronydTime
    installBaseRPM
    configYUM
    configPython3
}
