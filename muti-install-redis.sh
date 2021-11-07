#!/bin/bash
#单机部署redis
#serialt tang serialt@qq.com
#2020-02

ftp_server=192.168.122.15

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

network-ping() {
	if ! ping -c 1 ${ftp_server} >/dev/null; then
		echo_red " ${ftp_server} unknow !!!"
		echo_red " 请检查网络或稍后再试! "
		echo
		exit
	fi
}

download_redis() {
	network-ping
	if [ ! -f /usr/local/src/redis50.tar.gz ]; then
		echo_green "正在下载redis文件，请稍候......"
		wget -O /usr/local/src/redis50.tar.gz ftp://${ftp_server}/app/redis50.tar.gz &>/dev/null
		echo_green "下载redis压缩包 OK "
	fi
}

install_redis() {
	rm -rf /usr/local/redis
	tar -xf /usr/local/src/redis50.tar.gz -C /usr/local/
	echo_green "解压redis压缩包成功"
	mkdir -p /usr/local/redis/muti-redis
	echo-green "请输入要安装的redis数："
	read num
	echo-green "请输入要定义的redis的初始端口(默认6379)："
	read redis_port
	if [ -z $redis_port ]; then
		redis_port=6379
	fi
	for ((i = 1; i <= $num; i++)); do
		mkdir -p /usr/local/redis/muti-redis/redis-$redis_port
		cp /usr/local/redis/redis.conf /usr/local/redis/muti-redis/redis-${redis_port}/
		cp /usr/local/redis/sentinel.conf /usr/local/redis/muti-redis/redis-${redis_port}/
		redis_conf=/usr/local/redis/muti-redis/redis-${redis_port}/redis.conf
		sed -ri "69c \bind $(ifconfig eth0 | awk '/netmask/{print $2}')" $redis_conf
		sed -ri "88c \protected-mode no" $redis_conf
		sed -ri "/pidfile/s/redis_6379.pid/redis_${redis_port}.pid/" $redis_conf
		sed -ri "/port 6379/s/6379/$redis_port/" $redis_conf
		sed -ri "/daemonize no/s/no/yes/" $redis_conf
		sed -ri "171c \logfile /usr/local/redis/muti-redis/redis-${redis_port}/redis.log" $redis_conf
		sed -ri "263c \dir /usr/local/redis/muti-redis/redis-${redis_port}/" $redis_conf
		sed -ri "832c \cluster-enabled yes" $redis_conf
		sed -ri "840c \cluster-config-file node-${redis_port}.conf" $redis_conf
		sed -ri "846c \cluster-node-timeout 5000" $redis_conf
		sed -ri "/appendonly/s/no/yes/" $redis_conf
		sentinel_port=2${redis_port}
		sentinel_conf=/usr/local/redis/muti-redis/redis-${redis_port}/sentinel.conf
		sed -ri "/daemonize no/s/no/yes/" $sentinel_conf
		sed -ri "/port 26379/s/26379/$sentinel_port/" $sentinel_conf
		sed -ri "31c \pidfile /var/run/redis-${sentinel_port}-sentinel.pid" $sentinel_conf
		sed -ri "/protected-mode no/s/yes/no/" $sentinel_conf
		sed -ri "65c \dir /usr/local/redis/muti-redis/redis-${redis_port}/" $sentinel_conf
		sed -ri "36c \logfile /usr/local/redis/muti-redis/redis-${redis_port}/sentinel.log" $sentinel_conf
		echo_green "redis-${redis_port} is OK!!!"
		redis_port=$(($redis_port + 1))
	done
}

start_redis() {
	for m in $(ls /usr/local/redis/muti-redis/); do
		mm=/usr/local/redis/muti-redis/$m
		/usr/local/redis/bin/redis-server $mm/redis.conf

	done
}

stop_redis() {

	for m in $(ss -anpl | awk '/redis/{print $5}' | awk -F: '{print $2}'); do
		/usr/local/redis/bin/redis-cli -p $m shutdown &>/dev/null

	done

}

stop_redis_force() {
	for m in $(ps -ef | awk '/redis-server/{print $2}'); do
		kill -9 $m

	done
	sleep 1

}

cluster_redis() {
	stop_redis_force
	download_redis
	rm -rf /usr/local/redis
	tar -xf /usr/local/src/redis50.tar.gz -C /usr/local/
	echo_green "解压redis压缩包成功"
	mkdir -p /usr/local/redis/muti-redis
	echo-green "请输入要安装的redis数："
	read num
	echo-green "请输入要定义的redis的初始端口(默认6379)："
	read redis_port
	if [ -z $redis_port ]; then
		redis_port=6379
	fi
	cluster_redis_port=$redis_port
	cluster_redis_num=$num
	echo-green "请输入redis集群中每个master带的slave数[默认 1 ]："
	read slave_num
	if [ -z $slave_num ]; then
		slave_num=1
	fi
	for ((i = 1; i <= $num; i++)); do
		mkdir -p /usr/local/redis/muti-redis/redis-$redis_port
		cp /usr/local/redis/redis.conf /usr/local/redis/muti-redis/redis-${redis_port}/
		cp /usr/local/redis/sentinel.conf /usr/local/redis/muti-redis/redis-${redis_port}/
		redis_conf=/usr/local/redis/muti-redis/redis-${redis_port}/redis.conf
		sed -ri "69c \bind $(ifconfig eth0 | awk '/netmask/{print $2}')" $redis_conf
		sed -ri "88c \protected-mode no" $redis_conf
		sed -ri "/pidfile/s/redis_6379.pid/redis_${redis_port}.pid/" $redis_conf
		sed -ri "/port 6379/s/6379/$redis_port/" $redis_conf
		sed -ri "/daemonize no/s/no/yes/" $redis_conf
		sed -ri "171c \logfile /usr/local/redis/muti-redis/redis-${redis_port}/redis.log" $redis_conf
		sed -ri "263c \dir /usr/local/redis/muti-redis/redis-${redis_port}/" $redis_conf
		sed -ri "832c \cluster-enabled yes" $redis_conf
		sed -ri "840c \cluster-config-file node-${redis_port}.conf" $redis_conf
		sed -ri "846c \cluster-node-timeout 5000" $redis_conf
		sed -ri "/appendonly/s/no/yes/" $redis_conf
		sentinel_port=2${redis_port}
		sentinel_conf=/usr/local/redis/muti-redis/redis-${redis_port}/sentinel.conf
		sed -ri "/daemonize no/s/no/yes/" $sentinel_conf
		sed -ri "/port 26379/s/26379/$sentinel_port/" $sentinel_conf
		sed -ri "31c \pidfile /var/run/redis-${sentinel_port}-sentinel.pid" $sentinel_conf
		sed -ri "/protected-mode no/s/yes/no/" $sentinel_conf
		sed -ri "65c \dir /usr/local/redis/muti-redis/redis-${redis_port}/" $sentinel_conf
		sed -ri "36c \logfile /usr/local/redis/muti-redis/redis-${redis_port}/sentinel.log" $sentinel_conf
		echo_green "redis-${redis_port} is OK!!!"
		redis_port=$(($redis_port + 1))
	done
	start_redis
	cluster_group=
	for ((i = 1; i <= ${cluster_redis_num}; i++)); do
		echo $i
		cluster_group=${cluster_group}\ $(ifconfig eth0 | awk '/netmask/{print $2}'):${cluster_redis_port}
		cluster_redis_port=$((cluster_redis_port + 1))

	done

	echo $cluster_group

	/usr/bin/expect <<eof
set timeout 10
spawn	/usr/local/redis/bin/redis-cli --cluster create ${cluster_group} --cluster-replicas $slave_num
expect "Can I set the above configuration? (type 'yes' to accept):"
send "yes\r"
expect eof
eof
}

####main
menu() {
	echo
	echo_red "注意!!!!!"
	echo_red "一键部署redis集群需要expect"
	echo_red "若没有安装，请执行 yum -y install expect"
	echo
	echo_green "一键创建redis集群，请输入[ H ]"
	echo
	echo
	cat <<EOF
++++++++++++++++++++++++++
+	 redis管理	 +
++++++++++++++++++++++++++
+	1、安装redis	 +
+	2、启动redis	 +
+	3、停止redis	 +
+	4、重启redis	 +
+	5、强制停止redis +
+	h、创建redis集群 +
+	q、退出脚本	 +
++++++++++++++++++++++++++
EOF

}

while :; do
	menu
	echo-red "请输入："
	read choose
	case $choose in
	1)
		download_redis
		install_redis
		;;
	2)
		start_redis
		;;
	3)
		stop_redis
		;;
	4)
		stop_redis
		sleep 2
		start_redis
		;;
	5)
		stop_redis_force
		;;
	h | H)
		cluster_redis
		echo
		echo_red "  cluster redis 创建成功"
		echo
		echo
		read -p "按任意键继续！！！" any_key
		;;
	q)
		exit
		;;

	*)
		echo_red "无法识别，请重新输入！！！"
		;;
	esac
done
