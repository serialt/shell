#!/bin/bash
# ******************************************************
# Author       	:	serialt 
# Email        	:	serialt@qq.com
# Filename     	:	ssh_all.sh
# Version      	:	v1.0
# Created Time 	:	2020-08-02 14:59
# Last modified	:	2020-08-02 14:59
# By Modified  	: 
# Description  	: 	ssh免密登陆脚本
#  
# ******************************************************
  
HOSTS=(
192.168.122.113
192.168.122.114
192.168.122.115
192.168.122.116
192.168.122.117
)
PASSWORD=(
centos
centos
centos
centos
centos
)


#install expect
installExpect(){
        # if expect not exits,then install expect
	rpm -qa | grep expect
        if [ $? -ne 0 ] 
        then
                yum -y install expect
        fi
}

#生成密钥对
keyGenerate(){
	if [ -f $HOME/.ssh/id_rsa ]
	then 
		:
	else
		ssh-keygen -t rsa -P "" -f /root/.ssh/id_rsa
	fi
}

#清理已存在的密钥
clearKey(){
	rm -rf  /root/.ssh/known_hosts
}


#安装expect和免密登陆
# $1:host   
# $2:password
autoSshCopyId(){

	/usr/bin/expect <<-EOF
	spawn 	ssh-copy-id -i $HOME/.ssh/id_rsa.pub  root@$1
	expect 	"(yes/no)?"
	send 	"yes\r"
	expect 	"password:"
	send 	"$2\r"
	expect eof
	EOF

}

main(){
	installExpect
	keyGenerate
#	clearKey
	
	lenHOSTS=${#HOSTS[@]}
	for ((i=0;i<$lenHOSTS;i++))
	do
		autoSshCopyId ${HOSTS[$i]} ${PASSWORD[$i]}

	done

}


main





















