#!/bin/bash
# ******************************************************
# Author       	:	serialt 
# Email        	:	serialt@qq.com
# Filename     	:	docker_install.sh
# Version      	:	v1.0
# Created Time 	:	2020-07-05 21:06
# Last modified	:	2020-07-05 21:06
# By Modified  	: 
# Description  	:       install docker-ce on centos7
#  
# ******************************************************



green_col='\E[0;32m'
red_col="\e[1;31m"
blue_col="\e[1;34m"
reset_col="\e[0m"

###输出换行
echo_red(){
        echo -e "${red_col}$*${reset_col}"
}
echo_green(){
        echo -e "${green_col}$*${reset_col}"
}
echo_blue(){
        echo -e "${blue_col}$*${reset_col}"
}

###输出不换行
echo-red(){
        echo -en "${red_col}$*${reset_col}"
}
echo-green(){
        echo -en "${green_col}$*${reset_col}"
}
echo-blue(){
        echo -en "${blue_col}$*${reset_col}"
}


checkOs(){
    . /etc/os-release && echo ${ID}
}


# $* 

uninstallDocker(){
    OS_ID=`checkOs`
    case $OS_ID in
        'centos' | 'rhel')
                yum -y remove docker docker-common docker-selinux docker-engine  
                ;;
        'ubuntu' | 'debian')
                apt-get -y remove docker docker-engine docker.io
                ;;
        '*')
                echo_red "识别操作系统失败，无法卸载docker"
                exit                
                ;;
    esac
}


# huawei,aliyun,tsinghua,bfsu,ustc,tencent,163,zju
getUrl(){
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


configRepo(){
    OS_ID=`checkOs`
    MIRROR_URL=`getUrl $1`
    case $OS_ID in
        'centos' | 'rhel')
                curl -o /etc/yum.repos.d/docker-ce.repo ${MIRROR_URL}/docker-ce/linux/centos/docker-ce.repo
                sed -i "s+https://download.docker.com+${MIRROR_URL}/docker-ce+" /etc/yum.repos.d/docker-ce.repo    
                yum makecache fast
                ;;
        'ubuntu')
                curl -fsSL ${MIRROR_URL}/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
                sudo add-apt-repository "deb [arch=amd64] ${MIRROR_URL}/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
                apt-get update
                ;;
        'debian')
                curl -fsSL ${MIRROR_URL}/docker-ce/linux/debian/gpg | sudo apt-key add -
                sudo add-apt-repository "deb [arch=amd64] ${MIRROR_URL}/docker-ce/linux/debian $(lsb_release -cs) stable"
                apt-get update
                ;;    
        '*')
                echo_red "识别操作系统失败，无法卸载docker"
                exit                
                ;;
    esac    
}

installDocker(){
    OS_ID=`checkOs`
    case $OS_ID in
        'centos' | 'rhel')
                yum -y install -y yum-utils device-mapper-persistent-data lvm2
                yum -y install docker-ce      
                ;;
        'ubuntu' | 'debian')
                apt-get -y install apt-transport-https ca-certificates curl gnupg2 software-properties-common
                apt-get -y install docker-ce
                ;;
        *)
                echo_red "识别操作系统失败，无法卸载docker"
                exit                
                ;;
    esac
}

installDockercompose(){
    curl -L "https://get.daocloud.io/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
       && chmod +x /usr/local/bin/docker-compose
}

configDocker(){
    [ ! -d /etc/docker ] && mkdir -p /etc/docker
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
}

startDocker(){
    systemctl enable docker
    systemctl restart docker
}




main(){
    args_num=$#
    which docker &> /dev/null
    if [ $? == 0 ] ;then
        if [ ${args_num} == 0 ];then
            echo_red "docker已经安装"
            echo_green "如果要卸载旧的docker则运行：" $0 install 
            exit
        elif [ $1 == 'install' ];then 
	    uninstallDocker
        else
            echo_red "输入无法识别"
            echo_blue 安装docker: ./${0}   
            echo_blue 卸载已安装的docker: ./${0} install
            exit   
        fi
    fi

    # huawei,aliyun,tsinghua,bfsu,ustc,tencent,163,zju
    configRepo ustc
    installDocker
    configDocker
    #installDockercompose
    startDocker
    echo_green docker安装和配置已完成
}


main $*

