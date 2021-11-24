#!/bin/bash
# ******************************************************
# Author       	:	serialt 
# Email        	:	serialt@qq.com
# Filename     	:	openvpn-key.ssh
# Version      	:	v1.0
# Created Time 	:	2020-08-02 14:59
# Last modified	:	2020-08-02 14:59
# By Modified  	: 
# Description  	: 	安装 zabbix-agent
#  
# ******************************************************

# zabbix 仓库地址
# aliyun https://mirrors.aliyun.com
# huawei https://repo.huaweicloud.com
# tuna https://mirrors.tuna.tsinghua.edu.cn
ZABBIX_REPO_URL="https://mirrors.aliyun.com"

# zabbix server的地址
ZABBIX_SERVER="zabbix.imau.io"

# zabbix的版本
ZABBIX_VERSION="5.0"

# 支持agent与agent2
ZABBIX_AGENT_VERSION="agent2"









### 功能函数
# 定义颜色
green_col='\E[0;32m'
red_col="\e[1;31m"
blue_col="\e[1;34m"
reset_col="\e[0m"
# 输出换行
echo_red() {
    echo -e "${red_col}$1${reset_col}"
}

echo_green() {
    echo -e "${green_col}$1${reset_col}"
}

echo_blue() {
    echo -e "${blue_col}$1${reset_col}"
}

# 输出不换行
echo-red() {
    echo -en "${red_col}$1${reset_col}"
}

echo-green() {
    echo -en "${green_col}$1${reset_col}"
}

echo-blue() {
    echo -en "${blue_col}$1${reset_col}"
}


if grep -qs "ubuntu" /etc/os-release; then
    os="ubuntu"
    os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
    group_name="nogroup"
elif [[ -e /etc/debian_version ]]; then
    os="debian"
    os_version=$(grep -oE '[0-9]+' /etc/debian_version | head -1)
    group_name="nogroup"
elif [[ -e /etc/redhat-release || -e /etc/almalinux-release || -e /etc/rocky-release || -e /etc/centos-release ]]; then
    os="rhel"
    os_version=$(grep -shoE '[0-9]+' /etc/redhat-release /etc/almalinux-release /etc/rocky-release /etc/centos-release | head -1)
    group_name="nobody"
elif [[ -e /etc/fedora-release ]]; then
    os="fedora"
    os_version=$(grep -oE '[0-9]+' /etc/fedora-release | head -1)
    group_name="nobody"
else
    echo "This installer seems to be running on an unsupported distribution.
Supported distros are Ubuntu, Debian, AlmaLinux, Rocky Linux, CentOS and Fedora."
    exit
fi



installAgent(){
    which zabbix_agentd &> /dev/null
    if [[ $? -eq 0 ]];then
        echo_red "zabbix agent is installed, are you sure to remove to continue ? [y/n]"
        read yes_or_not
        [[ ${yes_or_not} != 'y' ]] && echo-red "input error" && exit
    fi

    which zabbix_agent2 &> /dev/null
    if [[ $? -eq 0 ]];then
        echo_red "zabbix agent2 is installed, are you sure to remove to continue ? [y/n]"
        read yes_or_not
        [[ ${yes_or_not} != 'y' ]] && echo-red "input error" && exit
    fi

    case $os in
        'rhel'|'fedora') 
            yum -y remove zabbix-agent zabbix-agent2 zabbix-release
            rpm -ivh ${ZABBIX_REPO_URL}/zabbix/zabbix/${ZABBIX_VERSION}/${os}/${os_version}/x86_64/zabbix-release-${ZABBIX_VERSION}-1.el${os_version}.noarch.rpm
            sed -ri "s#http://repo.zabbix.com#${ZABBIX_REPO_URL}/zabbix#g" /etc/yum.repos.d/zabbix.repo
         
            # install zabbix agent
            yum -y install zabbix-${ZABBIX_AGENT_VERSION}  chrony
        ;;
        'ubuntu'|'debian') 
            apt -y remove zabbix-agent
        ;;
        *) 
            echo_red "unsupported distribution"
            exit
        ;;
    esac

}

configureAgent(){
    ZABBIX_AGENT_CONF="zabbix_agentd"
    [[ ${ZABBIX_AGENT_VERSION} == 'agent2' ]] &&   ZABBIX_AGENT_CONF="zabbix-agent2"

    sed -ri -e  "/^Server=127.0.0.1/c \Server=${ZABBIX_SERVER}"    \
            -e  "/^ServerActive=127.0.0.1/c \ServerActive=${ZABBIX_SERVER}"  \
            -e  "/^Hostname/c \Hostname=`hostname -f`" /etc/zabbix/${ZABBIX_AGENT_CONF}.conf 


}

startAgent(){
    systemctl enable zabbix-${ZABBIX_AGENT_VERSION} --now
    systemctl enable chronyd --now
}



# main 
installAgent
configureAgent
startAgent


