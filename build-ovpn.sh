#!/usr/bin/env bash
# ******************************************************
# Author       	:	Tang
# Email        	:	tserialt@gmail.com
# Version      	:	v1.0
# Created Time 	:	2026-11-09 19:53
# Last modified	:	2026-11-09 00:29
# By Modified  	:
# Description  	:    生成ovpn证书
#
# ******************************************************


# ca.crt        /etc/openvpn/easy-rsa/pki
# server.crt    /etc/openvpn/easy-rsa/pki/issued
# user.crt      /etc/openvpn/easy-rsa/pki/issued
# user.key      /etc/openvpn/easy-rsa/pki/private
# ca.key        /etc/openvpn/easy-rsa/pki/private
# ta.key        /etc/openvpn/easy-rsa


# 定义用户
accounts=(
sugar1,sugar1
)


OPENVPN_DIR="/etc/openvpn"
EASY_RSA_DIR="/etc/openvpn/easy-rsa"

# 分配好的证书
OVPN_DIR="/tmp/openvpn"

# 创建key
# $1 用户证书名  
create_key(){
  [[ ! -f ${EASY_RSA_DIR}/easyrsa ]]  && exit 55
  cd ${EASY_RSA_DIR}/ && ./easyrsa build-client-full $1 nopass
}


# $1 用户名
create_ovpn(){
  [[ ! -f ${OVPN_DIR} ]] && mkdir -p ${OVPN_DIR}
  cat > ${OVPN_DIR}/$1.ovpn << EOF
client
dev tun
proto tcp
remote vpn.local.com 50000
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
comp-lzo
verb 3
EOF

}

# $1 用户名
insert_file(){
  ca=`cat ${EASY_RSA_DIR}/pki/ca.crt`
  user_crt=`cat ${EASY_RSA_DIR}/pki/issued/$1.crt`
  user_key=`cat ${EASY_RSA_DIR}/pki/private/$1.key`
  ta=`cat ${EASY_RSA_DIR}/ta.key`

cat >> ${OVPN_DIR}/$1.ovpn << EOF
<ca> 
${ca}
</ca>
<cert> 
${user_crt}
</cert>
<key> 
${user_key}
</key>
key-direction 1 
<tls-auth> 
${ta}
</tls-auth>
EOF

}

## main
for aobj in ${accounts[@]}
do
  arr=(${aobj//,/ })
  actName=${arr[0]}
  chineseName=${arr[1]}

  create_ovpn ${actName}
  create_key ${actName}
  insert_file ${actName}
done