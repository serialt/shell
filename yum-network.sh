#!/bin/bash
# ******************************************************
# Author       	:	serialt
# Email        	:	serialt.qq.com
# Filename     	:	yum-network.sh
# Created Time 	:	2020-03-07 16:14
# Last modified	:	2020-03-21 14:32
# Description  	:       get base repo file from network
#
# ******************************************************

green_col='\E[0;32m'
red_col="\e[1;31m"
blue_col="\e[1;34m"
reset_col="\e[0m"

###输出换行
echo_red() {
    echo -e "${red_col}$1${reset_col}"
}

echo_green() {
    echo -e "${green_col}$1${reset_col}"
}

echo_blue() {
    echo -e "${blue_col}$1${reset_col}"
}

###输出不换行

echo-red() {
    echo -en "${red_col}$1${reset_col}"
}

echo-green() {
    echo -en "${green_col}$1${reset_col}"
}

echo-blue() {
    echo -en "${blue_col}$1${reset_col}"
}

###test network and download wget
network_test() {
    ping -c 1 www.baidu.com &>/dev/null
    if [ $? -ne 0 ]; then
        exit
    fi
    which wget &>/dev/null
    if [ $? -ne 0 ]; then
        echo_blue "wget is installing,please waite"
        yum -y install wget &>/dev/null

        if [ $? -ne 0 ]; then
            echo_red "wget install failed"
            exit
        fi
    fi
    echo_green "wget install succeed !"
}

succeed() {
    echo
    echo_green " $1 repo file crated "
}

bak_repo() {
    if [ -f /etc/yum.repos.d/bak ]; then
        mv -f /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak/ &>/dev/null
    else
        mkdir -p /etc/yum.repos.d/bak
        \cp /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak/ &>/dev/null

    fi
    echo
    echo_green "******备份成功******"
    echo
}

aliyun_repo() {
    wget -O /etc/yum.repos.d/aliyun.repo http://mirrors.aliyun.com/repo/Centos-7.repo &>/dev/null
    succeed 'aliyun'
}

neteasy_repo() {
    wget -O /etc/yum.repos.d/163.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo &>/dev/null
    succeed 'neteasy'
}

huaweicloud_repo() {
    wget -O /etc/yum.repos.d/huaweicloud.repo https://mirrors.huaweicloud.com/repository/conf/CentOS-7-anon.repo &>/dev/null
    succeed 'huaweicloud'
}

epel_huawei_repo() {
    yum -y install epel-release &>/dev/null
    rm -rf /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel.repo
    wget -O /etc/yum.repos.d/epel-huawei.repo https://mirrors.huaweicloud.com/repository/conf/epel-7-anon.repo &>/dev/null
    succeed 'epel_huawei'
}

local_repo() {
    cat >/etc/yum.repos.d/local.repo <<EOF
[local]
name=local iso
baseurl=file:///cdrom
enabled=1
gpgcheck=0
EOF
    succeed 'local'
}

menu() {
    cat <<eof
====================================
+             配置yum源            +
====================================
+         1、aliyun                +
+         2、neteasy-163           +  
+         3、huaweicloud           +
+         4、安装epel-release      +
+         5、配置本地yum源         +
+         b、备份本地已有的yum源   +
+         d、delete all repo file  +
+         l、显示所有的repo文件    +
+         q、exit                  +
+                                  +
====================================
eof
}

#####main
network_test
while :; do
    clear
    menu
    echo-blue "inpute the number:"
    read select
    case $select in

    1)
        aliyun_repo
        ;;
    2)
        neteasy_repo
        ;;
    3)
        huaweicloud_repo
        ;;
    4)
        epel_huawei_repo
        ;;
    5)
        local_repo
        ;;
    q)
        echo
        echo_red "感谢使用yum-network.sh !!!"
        echo
        exit
        ;;
    b)
        bak_repo
        ;;
    d)
        rm -rf /etc/yum.repos.d/*.repo
        echo
        echo_green "成功删除所有repo文件"
        ;;

    l)
        echo
        ls /etc/yum.repos.d | \grep ".repo"
        echo
        ;;
    *)
        echo "unknown"
        ;;
    esac
    echo
    echo_red "input any key to continue !!!"
    read
done
