#!/bin/bash
# ******************************************************
# Author       	:	serialt
# Email        	:	serialt@qq.com
# Filename     	:	add_user_imau.sh
# Version      	:	v1.0
# Created Time 	:	2020-08-02 14:59
# Last modified	:	2020-08-02 14:59
# By Modified  	:
# Description  	: 	创建一个sudo免密的用户
#
# ******************************************************

#set -eu
#set -o pipefail
set -u

SSH_PUBLIC_KEY='ssh key serialt-dev serialt@qq.com'
SSH_USER='imau'

check_os() {
    . /etc/os-release && echo ${ID}
}

add_public_key() {
    id ${SSH_USER} &>/dev/null
    [[ $? -ne 0 ]] && useradd -m ${SSH_USER} -s /bin/bash
    su - ${SSH_USER} -c "
        if [ ! -d ~/.ssh ];then 
            mkdir ~/.ssh && chmod 700 ~/.ssh
            echo ${SSH_PUBLIC_KEY} >> ~/.ssh/authorized_keys 
            chmod 600 ~/.ssh/authorized_keys
        else
            echo ${SSH_PUBLIC_KEY} >> ~/.ssh/authorized_keys
            chmod 600 ~/.ssh/authorized_keys
        fi
        "

}

add_sudo_user() {
    echo "${SSH_USER} ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers
}

main() {

    add_public_key
    add_sudo_user
    echo "增加用户和密钥成功"
}

main
