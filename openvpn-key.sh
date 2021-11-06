#!/bin/bash
# ******************************************************
# Author       	:	serialt
# Email        	:	serialt@qq.com
# Filename     	:	openvpn.sh
# Created Time 	:	2021-10-20 14:55
# Last modified	:	2021-10-20 14:55
# Description  	: 参考 https://github.com/Nyr/openvpn-install
#
# ******************************************************

accounts=(
  client3,ccc
  client4,ddd
)

### openvpn 配置区域
OPENVPN_DIR="/etc/openvpn"
EASY_RSA_DIR="/etc/openvpn/easy-rsa"
OPENVPN_SERVER_HOST="vpn.imau.io"
OPENVPN_SERVER_PORT="50000"

# 分配好的证书
OVPN_DIR="/tmp/openvpn"

### 创建用户证书
# 创建key
# $1 用户证书名
create_key() {
  [[ ! -d ${EASY_RSA_DIR} ]] && exit 55
  cd ${EASY_RSA_DIR}/ && ./easyrsa build-client-full $1 nopass
}

# 创建配置文件模版
# $1 用户名
create_ovpn() {
  [[ ! -f ${OVPN_DIR} ]] && mkdir -p ${OVPN_DIR}
  cat >${OVPN_DIR}/$1.ovpn <<EOF
client
dev tun
proto tcp
remote ${OPENVPN_SERVER_HOST} ${OPENVPN_SERVER_PORT}
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verb 3
EOF

}

# 获取证书并插入到 .ovpn 的配置文件里
# $1 用户名
insert_file() {
  ca=$(cat ${EASY_RSA_DIR}/pki/ca.crt)
  user_crt=$(cat ${EASY_RSA_DIR}/pki/issued/$1.crt)
  user_key=$(cat ${EASY_RSA_DIR}/pki/private/$1.key)
  ta=$(cat ${EASY_RSA_DIR}/ta.key)

  cat >>${OVPN_DIR}/$1.ovpn <<EOF
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
for aobj in ${accounts[@]}; do
  arr=(${aobj//,/ })
  actName=${arr[0]}

  create_ovpn ${actName}
  create_key ${actName}
  insert_file ${actName}
done
