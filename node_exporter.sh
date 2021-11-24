#!/bin/bash
# ******************************************************
# Author       	:	serialt 
# Email        	:	serialt@qq.com
# Filename     	:	node_exporter.sh
# Version      	:	v1.0
# Created Time 	:	2020-08-02 14:59
# Last modified	:	2020-08-02 14:59
# By Modified  	: 
# Description  	: 	安装 node_exporter
#  
# ******************************************************


### setup
NODE_EXPORTER_DOWNLOAD_URL='https://s3.jcloud.sjtu.edu.cn/899a892efef34b1b944a19981040f55b-oss01/github-release/prometheus/node_exporter/releases/download/v1.3.0/node_exporter-1.3.0.linux-amd64.tar.gz'


NODE_EXPORTER_OPTION=''

NODE_EXPORTER_HOME="/usr/local/node_exporter"

SET_TLS='false'
SET_PWD='true'

CRT_FILE=''
KEY_FILE=''

BASIC_AUTH_USER='prometheus'
# centos
BASIC_AUTH_PWD='$2y$12$0IHIFk9TxJguz0vLS9VT9OYz0WHMiCL1YQ90lWXhMqyadQFN63Ow6'

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



installExporter(){
    node_path=$(which node_exporter)
    if [[ $? -eq 0 ]];then
        node_exporter --version
        echo_red "node_exporter is installed, are you sure to remove to continue ? [y/n]"
        read yes_or_not
        [[ ${yes_or_not} != 'y' ]] && echo-red "input error" && exit
    fi    

    \mv ${node_path} /tmp/
    cd  ${NODE_EXPORTER_HOME} && rm -rf  ./node_exporter

    which wget &> /dev/null
    if [[ $? -ne 0 ]] ;then
        case $os in
            'rhel'|'fedora') 
                yum -y install wget
            ;;
            'ubuntu'|'debian') 
                apt -y install wget
            ;;
            *) 
                echo_red "unsupported distribution"
                exit
            ;;
        esac
    fi 

    wget -P /tmp/ ${NODE_EXPORTER_DOWNLOAD_URL}
    fileName=$(echo ${NODE_EXPORTER_DOWNLOAD_URL} | awk -F'/' '{print $NF}')
    tar -xf /tmp/${fileName} -C /tmp/
    EXPORTER_NAME=$(echo ${fileName} | awk -F'.tar.gz' '{print $1}')
    [[ ! -d ${NODE_EXPORTER_HOME} ]] && mkdir -p ${NODE_EXPORTER_HOME} 
    \mv /tmp/${EXPORTER_NAME}/* ${NODE_EXPORTER_HOME}/


}

exporterConfig(){
    if [[ ${SET_TLS} == 'true' ]] || [[ ${SET_PWD} == 'true' ]] ;then
        sed -ri "/ExecStart/a \        --web.config=${NODE_EXPORTER_HOME}/config.yaml  \\\\" /etc/systemd/system/node_exporter.service
    fi

    if [[ ${SET_TLS} == 'true' ]] ;then 
        echo ${CRT_FILE} > ${NODE_EXPORTER_HOME}/node_exporter.crt
        echo ${KEY_FILE} > ${NODE_EXPORTER_HOME}/node_exporter.key
        cat > ${NODE_EXPORTER_HOME}/config.yaml <<EOF
tls_server_config:
  cert_file: node_exporter.crt
  key_file: node_exporter.key
EOF
    fi
    [[ ${SET_TLS} == 'true' ]] && [[ ${SET_PWD} == 'true' ]] && cat >> ${NODE_EXPORTER_HOME}/config.yaml <<EOF
basic_auth_users:
  # 当前设置的用户名为 prometheus ， 可以设置多个
  ${BASIC_AUTH_USER}: ${BASIC_AUTH_PWD}
EOF

    [[ ${SET_TLS} != 'true' ]] && [[ ${SET_PWD} == 'true' ]] && cat > ${NODE_EXPORTER_HOME}/config.yaml <<EOF
basic_auth_users:
  # 当前设置的用户名为 prometheus ， 可以设置多个
  ${BASIC_AUTH_USER}: ${BASIC_AUTH_PWD}
EOF

}

systemdConfig(){
cat >/etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=NodeExporter
Requires=network.target remote-fs.target
After=network.target remote-fs.target

[Service]
Type=simple
User=root
KillMode=process
ExecStart=${NODE_EXPORTER_HOME}/node_exporter \\
        --collector.systemd 
ExecReload=/bin/kill -HUP $MAINPID
TimeoutStartSec=4
Restart=on-failure


[Install]
WantedBy=multi-user.target
EOF

}



# main 
installExporter
systemdConfig
exporterConfig




systemctl daemon-reload
systemctl enable node_exporter --now
systemctl restart node_exporter
# firewall-cmd --zone=public --add-port=9100/tcp --permanent
# systemctl reload firewalld
# ufw allow 9100/tcp


