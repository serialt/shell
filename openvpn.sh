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

# ca.crt        /etc/openvpn/easy-rsa/pki
# server.crt    /etc/openvpn/easy-rsa/pki/issued
# user.crt      /etc/openvpn/easy-rsa/pki/issued
# user.key      /etc/openvpn/easy-rsa/pki/private
# ca.key        /etc/openvpn/easy-rsa/pki/private
# ta.key        /etc/openvpn/easy-rsa

### work dir
OPENVPN_DIR="/etc/openvpn"
EASY_RSA_DIR="/etc/openvpn/easy-rsa"

# 分配好的证书
OVPN_DIR="/tmp/openvpn"

# openvpn server
OPENVPN_SERVER_HOST="vpn.imau.io"
OPENVPN_SERVER_PORT="1194"

# push dns
PUSH_DNS1="114.114.114.114"
PUSH_DNS2="8.8.8.8"

# openvpn subnet
OPENVPN_SUBNET="10.8.0.0 255.255.255.0"

# push route to client
PUSH_ROUTE=(
    10.8.0.0 255.255.0.0
    192.168.124.0 255.255.255.0
    10.100.0.0 255.255.0.0
    10.101.0.0 255.255.0.0
)

PUSH_DNS=(
    114.114.114.114
    8.8.8.8
)

# openssl config
EASYRSA_REQ_COUNTRY="CN"
EASYRSA_REQ_PROVINCE="Shanghai"
EASYRSA_REQ_CITY="Shanghai"
EASYRSA_REQ_ORG="IMAU"
EASYRSA_REQ_EMAIL="serialt@qq.com"
EASYRSA_REQ_OU="OPS"

EASYRSA_KEY_SIZE="4096"    # rsa加密的长度,2048/4096
EASYRSA_CA_EXPIRE="3650"   # ca证书的有效期,单位是天
EASYRSA_CERT_EXPIRE="3600" # 签发的证书有效期
EASYRSA_CRL_DAYS="1000"    # 控制吊销证书的crl文件的下一次更新时间，默认3个月
EASYRSA_CERT_RENEW="30"    # renew证书的有效期

### 系统准备
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

# Detect Debian users running the script with "sh" instead of bash
if readlink /proc/$$/exe | grep -q "dash"; then
    echo 'This installer needs to be run with "bash", not "sh".'
    exit
fi

# Discard stdin. Needed when running from an one-liner which includes a newline
read -N 999999 -t 0.001

# Detect OpenVZ 6
if [[ $(uname -r | cut -d "." -f 1) -eq 2 ]]; then
    echo "The system is running an old kernel, which is incompatible with this installer."
    exit
fi

# Detect OS
# $os_version variables aren't always in use, but are kept here for convenience
if grep -qs "ubuntu" /etc/os-release; then
    os="ubuntu"
    os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
    group_name="nogroup"
elif [[ -e /etc/debian_version ]]; then
    os="debian"
    os_version=$(grep -oE '[0-9]+' /etc/debian_version | head -1)
    group_name="nogroup"
elif [[ -e /etc/almalinux-release || -e /etc/rocky-release || -e /etc/centos-release ]]; then
    os="centos"
    os_version=$(grep -shoE '[0-9]+' /etc/almalinux-release /etc/rocky-release /etc/centos-release | head -1)
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

if [[ "$os" == "ubuntu" && "$os_version" -lt 1804 ]]; then
    echo "Ubuntu 18.04 or higher is required to use this installer.
This version of Ubuntu is too old and unsupported."
    exit
fi

if [[ "$os" == "debian" && "$os_version" -lt 9 ]]; then
    echo "Debian 9 or higher is required to use this installer.
This version of Debian is too old and unsupported."
    exit
fi

if [[ "$os" == "centos" && "$os_version" -lt 7 ]]; then
    echo "CentOS 7 or higher is required to use this installer.
This version of CentOS is too old and unsupported."
    exit
fi

# Detect environments where $PATH does not include the sbin directories
if ! grep -q sbin <<<"$PATH"; then
    echo '$PATH does not include sbin. Try using "su -" instead of "su".'
    exit
fi

if [[ "$EUID" -ne 0 ]]; then
    echo "This installer needs to be run with superuser privileges."
    exit
fi

if [[ ! -e /dev/net/tun ]] || ! (exec 7<>/dev/net/tun) 2>/dev/null; then
    echo "The system does not have the TUN device available.
TUN needs to be enabled before running this installer."
    exit
fi

# 安装openvpn和easy-rsa
install_openvpn_easy-rsa() {
    yum -y install epel-release
    yum -y install openvpn easy-rsa

}

# 完善easy-rsa配置文件
config_easy_rsa() {
    case ${os} in
    centos | rocky | rhel)
        [[ ! -d ${EASY_RSA_DIR} ]] && mkdir -p ${EASY_RSA_DIR}
        cp -rf /usr/share/easy-rsa/3/* /etc/openvpn/easy-rsa/
        cp -p /usr/share/doc/easy-rsa-3.*/vars.example /etc/openvpn/easy-rsa/vars
        sysctl -p | grep net.ipv4.ip_forward
        if [[ $? != 0 ]]; then
            echo "net.ipv4.ip_forward = 1" >>/etc/sysctl.conf
            sysctl -p
        fi

        ;;

    ubuntu)
        ccc
        ;;
    "*")
        echo_red "系统服务识别，请检查脚本或者操作系统"
        ;;

    esac

    # 配置easy-rsa
    sed -ri -e "/EASYRSA_REQ_COUNTRY/c \set_var EASYRSA_REQ_COUNTRY     \"${EASYRSA_REQ_COUNTRY}\"" \
        -e "/EASYRSA_REQ_PROVINCE/c \set_var EASYRSA_REQ_PROVINCE    \"${EASYRSA_REQ_PROVINCE}\"" \
        -e "/EASYRSA_REQ_CITY/c \set_var EASYRSA_REQ_CITY        \"${EASYRSA_REQ_CITY}\"" \
        -e "/EASYRSA_REQ_ORG/c \set_var EASYRSA_REQ_ORG         \"${EASYRSA_REQ_ORG}\"" \
        -e "/EASYRSA_REQ_EMAIL/c \set_var EASYRSA_REQ_EMAIL       \"${EASYRSA_REQ_EMAIL}\"" \
        -e "/EASYRSA_REQ_OU/c \set_var EASYRSA_REQ_OU          \"${EASYRSA_REQ_OU}\"" \
        -e "/EASYRSA_KEY_SIZE/c \set_var EASYRSA_KEY_SIZE       ${EASYRSA_KEY_SIZE}" \
        -e "/EASYRSA_CA_EXPIRE/c \set_var EASYRSA_CA_EXPIRE      ${EASYRSA_CA_EXPIRE} " \
        -e "/EASYRSA_CERT_EXPIRE/c \set_var EASYRSA_CERT_EXPIRE    ${EASYRSA_CERT_EXPIRE} " \
        -e "/EASYRSA_CRL_DAYS/c \set_var EASYRSA_CRL_DAYS       ${EASYRSA_CRL_DAYS} " \
        -e "/EASYRSA_CERT_RENEW/c \set_var EASYRSA_CERT_RENEW     ${EASYRSA_CERT_RENEW} " \
        ${EASY_RSA_DIR}/vars

    # easy-rsa创建证书
    cd ${EASY_RSA_DIR}/
    ./easyrsa init-pki
    # 创建无密码ca
    ./easyrsa build-ca nopass
    ./easyrsa build-server-full server nopass
    ./easyrsa gen-
    openvpn --genkey --secret ta.key
    ./easyrsa build-client-full client1 nopass
    [[ ! -d ${OPENVPN_DIR}/ccd ]] && mkdir ${OPENVPN_DIR}/ccd

    cat >${OPENVPN_DIR}/server.conf <<EOF
port 1194                		 # 监听端口
proto tcp                    # openvpn使用的协议
;proto udp
dev tun                      # mac上不允许使用tap模式， 

ca /etc/openvpn/server/ca.crt   			# openvpn使用的CA证书文件
cert /etc/openvpn/server/server.crt   # openvpn服务器端使用的证书文件
key /etc/openvpn/server/server.key    # openvpn服务器端使用的秘钥文件，该文件必须严格控制其安全性         
dh dh.pem                            # Diffie hellman文件

server 10.8.0.0 255.255.255.0        # 分配给客户端的子网，server端ip默认会设为.1的地址
ifconfig-pool-persist /var/log/openvpn/ipp.txt    # 定义client和虚拟ip地址之间的关系。在openvpn重启后再次连接的客户端将依然被分配和断开之前的IP地址

push "route 192.168.124.0 255.255.255.0"    
push "route 10.100.0.0 255.255.0.0"
push "route 10.101.0.0 255.255.0.0"   # 推送路由到客户端，允许客户端访问VPN服务器可访问的其他局域网
push "route 10.8.0.0 255.255.0.0"     # 推送vpn所在的网络的路由

client-config-dir ccd              # 用于连接客户端所在的子网，ccd目录里的文件名必须与openvpn用户名一致
route 192.168.100.0 255.255.255.0  # tom 用户所在的子网
route 192.168.120.0 255.255.255.0  # jerry 用户所在的子网 

# 示例1：打通tom用户所在的小型子网(192.168.10.0/24)，让其连接上vpn
# 在 /etc/openvpn/ccd/下创建以客户端命名的文件tom
#  iroute 192.168.10.0 255.255.255.0
#  push "route 10.8.0.0 255.255.255.0"     # 允许192.168.10.0/24这个子网连vpn所在的网络     

# 示例2：给jerry分配一个固定的IP地址10.8.0.200
# 创建以客户端命名的文件。设置客户端jerry为10.8.0.200这个IP地址，
# 只要在 /etc/openvpn/ccd/文件中包含如下行即可:
#  ifconfig-push 10.8.0.50 10.8.0.51
#  push "route 192.168.130.0 255.255.255.0"   # 只给jerry用户推送到192.168.130.0/24这个子网的路由
#  push “redirect-gateway def1 bypass-dhcp”   # 这条命令可以重定向客户端的网关，在进行翻墙时会使用到
   
    
;push "redirect-gateway def1 bypass-dhcp"     # 所有客户端的默认网关都将重定向到VPN,client发起的所有请求都通过OpenVPN服务器 

;push "dhcp-option DNS 10.10.10.10"        # 向客户端推送私有DNS
;push "dhcp-option DNS 114.114.114.114"    # 向客户端推送公共DNS

;client-to-client        # 客户端之间可以互相访问，默认设置下客户端间是不能相互访问的             
;duplicate-cn            #定义openvpn一个证书在同一时刻是否允许多个客户端接入，默认没有启用，(若开启仅用于测试目的)
keepalive 10 120         #设置服务端检测的间隔和超时时间 每10秒ping一次，如果120秒没有回应则认为对方已经down

tls-auth ta.key 0     	 # "HMAC 防火墙"可以帮助抵御DoS攻击和UDP端口淹没攻击，第二个参数在服务器端应该为'0'，在客户端应该为'1'

cipher AES-256-CBC       # v2.4客户端/服务器将自动以TLS模式协商AES-256-GCM，请参阅手册中的ncp-cipher选项
compress lz4-v2          # 在VPN链接上启用压缩并将选项推送到客户端
push "compress lz4-v2"
;comp-lzo                # 对于与旧客户端兼容的压缩，使用comp-lzo
;max-clients 100         # 允许并发连接的客户端的最大数量
user nobody
group nobody             # 定义openvpn运行时使用的用户和用户组
persist-key              # 持久化选项可以尽量避免访问那些在重启之后由于用户权限降低而无法访问的某些资源
persist-tun             
status /var/log/openvpn/openvpn-status.log  # 把openvpn的一些状态信息写到文件中，比如客户端获得的IP地址
;log    /var/log/openvpn/openvpn.log        # 记录日志，每次重新启动openvpn后删除原有的log信息。
log-append  /var/log/openvpn/               # 记录日志，每次重新启动openvpn后追加原有的log信息，

# 输出的日志级别
# 0 表示静默运行，只记录致命错误
# 4 表示合理的常规用法
# 5和6 可以帮助调试连接错误
# 9 表示极度冗余，输出非常详细的日志信息
verb 3                              # 设置日志记录冗长级别
;mute 20                            # 重复日志记录限额，相同类别的信息只有前20条会输出到日志文件中
;explicit-exit-notify 0             # UDP协议开启,通知客户端，当服务器重新启动时，可以自动重新连接
;crl-verify /etc/openvpn/easy-rsa/keys/crl.pem   # 用于记录吊销的用户，第一次销用户后才会生成，切记！！! 注销证书后一定要重启服务才会生效

;reneg-sec 0    # 默认值3600，也就是一个小时进行一次TSL重新协商，这个参数在服务端和客户端设置都有效，如果两边都设置了，就按照时间短的设定优先，当两边同时设置成0，表示禁用TSL重协商。使用OTP认证需要禁用
EOF
    # 生成client.conf配置文件模板
    cat >>${OPENVPN_DIR}/client.conf <<EOF
client                    # 声明这是client端 
dev tun                   # 使用tun
proto tcp                 # 使用tcp协议
remote vpn.imau.io 1194   # vpn server的地址和端口
remote ivpn.imau.io 1194  # 第二个vpn服务器， 如果有多个VPN服务器，为了实现负载均衡，可以设置多个remote指令
resolv-retry infinite     # 与服务器连接中断后将自动重新连接，这在网络不稳定的情况下(例如：笔记本电脑无线网络)非常有用
nobind										# 大多数客户端不需要绑定本机特定的端口号
persist-key               # 持久化选项可以尽量避免访问在重启时由于用户权限降低而无法访问的某些资源
persist-tun
ca ca.crt
cert serialt.crt
key serialt.key
remote-cert-tls server
tls-auth ta.key 1         # 如果在服务器上使用tls-auth密钥，那么每个客户端也必须拥有密钥
cipher AES-256-CBC
;comp-lzo									# 旧版客户端兼容的压缩
verb 3                    # 日志级别
;reneg-sec 0              # 默认值3600，也就是一个小时进行一次TSL重新协商，这个参数在服务端和客户端设置都有效，如果两边都设置了，就按照时间短的设定优先，当两边同时设置成0，表示禁用TSL重协商。使用OTP认证需要禁用
EOF
}

### create  ca,crt and key for server
#
create_ca_and_key() {
    cd ${EASY_RSA_DIR}
    ./easyrsa init-pki
    ./easyrsa build-ca nopass
    ./easyrsa build-server-full server nopass
    ./easyrsa build-client-full client nopass
    ./easyrsa gen-crl
    ./easyrsa gen-dh
    openvpn --genkey --secret ta.key
    cp pki/ca.crt pki/private/ca.key pki/issued/server.crt pki/private/server.key pki/crl.pem ${OPENVPN_DIR}/server/

}

### create server.conf
#
config_server_conf() {
    cd ${EASY_RSA_DIR}
    cp pki/private/server.key ${OPENVPN_DIR}/server/
    cp pki/ca.crt ${OPENVPN_DIR}/server/
    cp pki/issued/vpnserver.crt ${OPENVPN_DIR}/server/
    cp pki/dh.pem ${OPENVPN_DIR}/server/
    cp ${EASY_RSA_DIR}/ta.key ${OPENVPN_DIR}/

    sed -ri -e "/port/c \port ${OPENVPN_SERVER_PORT}" \
        -e "/server\ 10.8.0.0\ 255.255.255.0/c \server "
    ${OPENVPN_DIR}/server.conf

}

### 创建用户证书
# 创建key
# $1 用户证书名
create_key() {
    [[ ! -f ${EASY_RSA_DIR}/easyrsa ]] && exit 55
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
cipher AES-256-CBC
comp-lzo
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
    #create_key ${actName}
    insert_file ${actName}
done
