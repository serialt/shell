#!/usr/bin/env bash
# ***********************************************************************
# Description   : init the os
# Version       : 1.0
# Author        : serialt
# Email         : serialt@qq.com
# Github        : https://github.com/serialt
# Created Time  : 2021-12-13 16:18:23
# Last modified : 2021-12-13 18:21:34
# FilePath      : /shell/os_init.sh
# Other         : 
#               : 
# 
# 
#                 人和代码，有一个能跑就行
# 
# 
# ***********************************************************************


### 参数配置

# 仓库地址
# https://mirrors.aliyun.com
# https://repo.huaweicloud.com
# https://mirrors.tuna.tsinghua.edu.cn
# https://mirrors.bfsu.edu.cn
# http://mirrors.ustc.edu.cn
# https://mirrors.cloud.tencent.com
# http://mirrors.163.com
# http://mirrors.zju.edu.cn

REPO_URL='https://mirrors.aliyun.com'

# python 镜像仓库
# https://mirrors.aliyun.com/pypi/simple
# https://pypi.tuna.tsinghua.edu.cn/simple
# https://mirrors.bfsu.edu.cn/pypi/web/simple
# https://repo.huaweicloud.com/repository/pypi/simple
# https://mirrors.cloud.tencent.com/pypi/simple
# https://mirrors.163.com/pypi/simple



PYPI_URL='https://mirrors.aliyun.com/pypi/simple/'





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

echo_b
lue() {
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
    os_sub=$(grep '^ID=' /etc/os-release  | awk -F '"' '{print $2}')
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


# only for rhel
for_rhel(){
    if [[ ${os} == 'rhel' ]];then
        systemctl stop firewalld
        systemctl disable firewalld


        # stop and disable selinux
        local selinux_mode=$(grep '^SELINUX=' /etc/selinux/config | awk -F'=' '{print $2}')
        if [ ${selinux_mode} != "disabled" ]; then
            setenforce 0
            sed -i '/^SELINUX=/c SELINUX=disabled' /etc/selinux/config
        fi

        # 安装基础使用的软件
        yum -y install wget bash-completion vim-enhanced

        case ${os_sub} in
            'centos')
                sed -e 's|^mirrorlist=|#mirrorlist=|g' \
                    -e "s|^#baseurl=http://mirror.centos.org|baseurl=${REPO_URL}|g" \
                    -i.bak \
                    /etc/yum.repos.d/CentOS-*.repo
                ;;
            'rocky')  
                sed -e 's|^mirrorlist=|#mirrorlist=|g' \
                    -e "s|^#baseurl=http://mirror.centos.org|baseurl=${REPO_URL}|g" \
                    -i.bak \
                    /etc/yum.repos.d/Rocky-*.repo
                ;;
            ;;
            '*')
                echo "输入有误，无法识别"
                ;;
        esac

        yum -y install epel-release

        if [[ ${os_version} == 7 ]] ;then 
            sed -e 's|^metalink|#metalink|' \
                -e "s|^#baseurl=http://download.example/pub|baseurl=${REPO_URL}|" \
                -i.bak \
                -i /etc/yum.repos.d/epel*.repo
            
            ### configure sshd
            sed -ri '/UseDNS/cUseDNS no' /etc/ssh/sshd_config
            sed -ri '/GSSAPIAuthentication/cGSSAPIAuthentication no' /etc/ssh/sshd_config
            systemctl restart sshd
            systemctl enable sshd

        elif [[ ${os_version == 8 }]]; then
            sed -e 's|^metalink|#metalink|' \
                -e "s|^#baseurl=https://download.example/pub|baseurl=${REPO_URL}|" \
                -i.bak \
                -i /etc/yum.repos.d/epel*.repo
        fi

        ### chronyd 时间同步
        timedatectl set-timezone "Asia/Shanghai"
        yum -y install chrony
        systemctl restart chronyd
        systemctl enable chronyd

    fi
}



history() {
    if ! grep "HISTTIMEFORMAT" /etc/profile >/dev/null 2>&1; then
        echo '
	UserIP=$(who -u am i | cut -d"("  -f 2 | sed -e "s/[()]//g")
	export HISTTIMEFORMAT="[%F %T] [`whoami`] [${UserIP}] " ' >>/etc/profile
    fi
    sed -i "s/HISTSIZE=1000/HISTSIZE=999999999/" /etc/profile
    echo_green "[ history 优化 ] ==> OK"
}


configPython3() {
    yum -y install python3
    [ -f /etc/pip.conf ] && return
    echo "配置pip"
    cat >/etc/pip.conf <<EOF
[global]
index-url = https://repo.huaweicloud.com/repository/pypi/simple
trusted-host = repo.huaweicloud.com
timeout = 120
EOF
    echo_green "[ 安装配置python ] ==> OK"
}


installDocker(){
    case ${os} in
    'centos' | 'rhel')
        curl -o /etc/yum.repos.d/docker-ce.repo ${REPO_URL}/docker-ce/linux/centos/docker-ce.repo
        sed -i "s+https://download.docker.com+${REPO_URL}/docker-ce+" /etc/yum.repos.d/docker-ce.repo
        yum makecache fast
        ;;
    'ubuntu')
        curl -fsSL ${REPO_URL}/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] ${REPO_URL}/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
        apt-get update
        ;;
    'debian')
        curl -fsSL ${REPO_URL}/docker-ce/linux/debian/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] ${REPO_URL}/docker-ce/linux/debian $(lsb_release -cs) stable"
        apt-get update
        ;;
    '*')
        echo_red "识别操作系统失败，无法卸载docker"
        exit
        ;;
    esac
}

installDockercompose() {
    curl -L "https://get.daocloud.io/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose
}

configDocker(){
    [ ! -d /etc/docker ] && mkdir -p /etc/docker
    cat >/etc/docker/daemon.json << EOF
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
    "dns": [
      "172.12.78.3",
      "114.114.114.114"
      ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF
}