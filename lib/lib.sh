#!/bin/bash
# *********************************************************
# Author       	:	serialt 
# Email        	:	serialt@qq.com
# Filename     	:	lib.sh
# Version      	:	v1.0
# Created Time 	:	2020-11-30 16:08
# Last modified	:	2020-11-30 16:08
# By Modified  	: 
# Description  	: shell库函数
#				
#					
#  
# *********************************************************



#*********************************************************
#
# echo 输出优化
#
#*********************************************************

green_col='\E[0;32m'
red_col="\e[1;31m"
blue_col="\e[1;34m"
reset_col="\e[0m"

###输出换行
echo_red(){
  echo -e "${red_col}$1${reset_col}"
}

echo_green(){
  echo -e "${green_col}$1${reset_col}"
}

echo_blue(){
  echo -e "${blue_col}$1${reset_col}"
}


###输出不换行
echo-red(){
  echo -en "${red_col}$1${reset_col}"
}

echo-green(){
  echo -en "${green_col}$1${reset_col}"
}

echo-blue(){
  echo -en "${blue_col}$1${reset_col}"
}






#*********************************************************
#
# 系统参数和信息
#
#*********************************************************

# 系统和版本
system_version_v2() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

# 系统版本号
system_vrsion(){
    if [[ -s /etc/redhat-release ]];then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}


# 返回一个公网ipv4
system_ipv4() {
    [ -z ${IP} ] && IP=$( curl -s ipv4.icanhazip.com )
    [ -z ${IP} ] && IP=$( curl -s ipinfo.io/ip )
    [ ! -z ${IP} ] && echo ${IP} || echo
}

# 返回公网ip和ip归属地
# [root@serialt ~]# curl -L ip.tool.lu
# 当前IP: 218.82.138.187
# 归属地: 中国 上海 上海市
# 
GetIPAndLocation(){
    curl -L ip.tool.lu
}

# 查询IP的归属地 $1为ip
# [root@serialt ~]# GetIPLocation 223.5.5.5
# 中国  浙江省 杭州市 阿里云
GetIPLocation(){
    curl -s  https://ip.cn/index.php?ip=$1 | grep 'id="tab0_address"'  | awk -F '<' '{print $2}' | awk -F'>' '{print $2}'
}

#如果本地ip为私有地址，将返回公有地址
system_ipv4_pub() {
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( curl -s ipv4.icanhazip.com )
    [ -z ${IP} ] && IP=$( curl -s -T2 ipinfo.io/ip )
    [ ! -z ${IP} ] && echo ${IP} || echo
}

# 测试硬盘读写速度
system_iospeed() {
    (LANG=C dd if=/dev/zero of=test_xx bs=64k count=16k conv=fdatasync && rm -f test_xx ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}

# 测试输入的是否为ip，$1填写ip
process_ip() {
    local status=$(echo $1|awk -F. '$1<=255&&$2<=255&&$3<=255&&$4<=255{print "yes"}')
    if echo $1|grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$">/dev/null;
then
	if [ status == "yes" ]; then
		return 0
	else
		return 1
	fi
else
	return 1
fi
}


# 转换大小写，$1为字符串，$2为1则大转小，为2则小转大，默认1
process_capital() {
    local a=1
    [ ! $a ] && a=1 || c=$2
	
    if [ $a -eq 1 ];then 
        echo $1 | tr "[A-Z]" "[a-z]"
    elif [ $a -eq 2 ];then
        echo $1 | tr "[a-z]" "[A-Z]"
    else
        return 1
    fi
}


#返回一个随机端口号
process_port() {
    shuf -i 9000-19999 -n 1
}

#随机密码，位置变量1可指定密码长度，默认6位
process_passwd(){
    local a=0 b="" c=6
    [ ! $1 ] && c=6 || c=$1
    
    for i in {a..z}; do arr[a]=${i}; a=`expr ${a} + 1`; done
    for i in {A..Z}; do arr[a]=${i}; a=`expr ${a} + 1`; done
    for i in {0..9}; do arr[a]=${i}; a=`expr ${a} + 1`; done
    for i in `seq 1 $c`; do b="$b${arr[$RANDOM%$a]}"; done
    echo ${b}
}

#一排横线，$1可指定长度，默认70
process_line() {
    local a=70
    [ ! $1 ] || a=$1
    
    printf "%-${a}s\n" "-" | sed 's/\s/-/g'
}

#倒计时，3秒
process_time() {
    local i
    for i in {3..1}
    do
        echo $i
        sleep 1
    done
}

#等待，打任意字结束，ctl+c将退出脚本
process_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}

#$1为字符，会将字符中的-变成_
process_bian() {
    local a="" i b
	
    for i in `seq 1 ${#1}`
    do
        b=`echo $1 | cut -c $i`
        [ "$b" == "-" ] && a=`echo ${a}_` || a=`echo ${a}${b}`
    done
	
    echo $a
}

# 判断是否为root用户，root用户输出0，非root用户输出1
is_root(){
    [[ $EUID -eq 0 ]] && echo '0' ||  echo '0';
}

# 使用systemctl启动，$1填写服务名
test_start() {
    for i in `echo $@`
    do
        systemctl status $i | grep 'Active: active (running)'
        if [[ $? -ne 0 ]];then
            systemctl restart $i
            systemctl status $i | grep 'Active: active (running)'
            [[ $? -eq 0 ]] || print_error "$i服务启动失败，请检查脚本" "Failed to start the $i service, please check the script"
        fi
        systemctl enable $i
    done
}

#测试是否可以联网
ping_www() {
    local a=`curl -o /dev/null --connect-timeout 3 -s -w "%{http_code}" www.baidu.com`
    [[ $a -eq 200 ]] || echo_red "当前环境需要连接网络，请检查网络问题或再次重试"
}

# 检查端口是否被占用，$1填写端口
check_port() {
    if [[ ! $1 ]];then
        return 1
    else
        for i in `echo $@`
        do
            which netstat
            [[ $? -ne 0 ]] && echo_red "netstat 没有在PATH中发现"
            netstat -unltp | grep -w :${i}
            [[ $? -eq 0 ]] && echo_red "${i}端口被占用，请检查端口或修改脚本" 

        done
    fi
}


#处理历史命令结果
function history(){
	if ! grep "HISTTIMEFORMAT" /etc/profile >/dev/null 2>&1
	then echo '
	UserIP=$(who -u am i | cut -d"("  -f 2 | sed -e "s/[()]//g")
	export HISTTIMEFORMAT="[%F %T] [`whoami`] [${UserIP}] " ' >> /etc/profile;
	fi
	sed -i "s/HISTSIZE=1000/HISTSIZE=999999999/" /etc/profile
    echo "[history 优化] ==> OK"
}
