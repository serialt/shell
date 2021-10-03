#!/bin/bash

create_v_host(){
	read -p "创建虚拟机的个数: " count
	read -p "输入虚拟机名称: " name
	for((i=1;i<=$count;i++))
	do
		qemu-img create -f qcow2 -b /kvm/centos7u7-template.img /kvm/${name}-${i}.img
		cp /etc/libvirt/qemu/centos7u7-template.xml /etc/libvirt/qemu/${name}-${i}.xml
		sed -i "/centos7u7-template/s/centos7u7-template/${name}-${i}/" /etc/libvirt/qemu/${name}-${i}.xml
		sed -i '/<uuid>/d' /etc/libvirt/qemu/${name}-${i}.xml
		sed -i '/<mac/d' /etc/libvirt/qemu/${name}-${i}.xml
		virsh define /etc/libvirt/qemu/${name}-$[i].xml
	done
}

start_v_host(){
	clear
	echo "========================="
	echo "=== 1.启动单台虚拟机  ==="
	echo "=== 2.启动多台虚拟机  ==="
	echo "=== 3.返回上层菜单    ==="
	echo "========================="
	read -p "选择您的操作[1|2|3]: " count
	case $count in
	1)
		read -p "输入启动虚拟机的名字: " name
		virsh start $name
	;;
	2)
		read -p "输入启动虚拟机的名字: " name
		for i in `virsh list --all |awk '{print $2}' |grep "$name"`
		do
			virsh start $i 2>/dev/null
		done
	;;
	3)
		return
	;;
	*)
		echo "选择正确编号"
	;;
	esac		
}

query_v_host(){
	x="n"
	while [ $x!="y" ]
	do
		echo "=========================="
		echo "==== 1.查看所有虚拟机 ===="
		echo "==== 2.查看已启动虚拟机 =="
		echo "==== 3.返回上层菜单     =="
		echo "=========================="
		read -p "选择您的操作[1|2|3]: " num
		case $num in
		1)
			virsh list --all
		;;
		2)
			virsh list
		;;
		3)
			break
		;;
		*)
			echo "选择正确编号"
		;;
		esac
		read -p "是否返回上层菜单: " x
	done
}

stop_v_host(){
	echo "========================="
	echo "=== 1.停止单台虚拟机  ==="
	echo "=== 2.停止多台虚拟机  ==="
	echo "=== 3.返回上层菜单    ==="
	echo "========================="
	read -p "选择您的操作[1|2|3]: " count
	virsh list
	case $count in
	1)
		read -p "输入启动虚拟机的名字: " name
		virsh destroy $name
	;;
	2)
		read -p "输入启动虚拟机的名字: " name
		for i in `virsh list --all |awk '{print $2}' |grep "$name"`
		do
			virsh destroy $i 2>/dev/null
		done
	;;
	3)
		return
	;;
	*)
		echo "输入正确操作"
	;;
	esac		
}

delete_v_host(){
	echo "========================="
	echo "=== 1.删除单台虚拟机  ==="
	echo "=== 2.删除多台虚拟机  ==="
	echo "=== 3.返回上层菜单    ==="
	echo "========================="
	read -p "选择您的操作[1|2|3]: " count
	virsh list --all
	case $count in
	1)
		read -p "输入启动虚拟机的名字: " name
		virsh destroy $name &>/dev/null
		virsh undefine $name &>/dev/null
		rm -rf /kvm/${name}.img
	;;
	2)
		read -p "输入启动虚拟机的名字: " name
		for i in `virsh list --all |awk '{print $2}' |grep "$name"`
		do
			virsh destroy ${i} &>/dev/null
			virsh undefine ${i} &>/dev/null
			rm -rf /kvm/${i}.img
		done
	;;
	3)
		return
	;;
	*)
		echo "输入正确编号"
	;;
	esac	
}

alter_v_host(){
	echo "========================="
	echo "=== 1.修改单台虚拟机  ==="
	echo "=== 2.修改多台虚拟机  ==="
	echo "=== 3.返回上层菜单    ==="
	echo "========================="
	read -p "选择您的操作[1|2|3]: " count
	virsh list --all
	case $count in
	1)
		read -p "输入修改虚拟机的名字: " name
		guestmount -a /kvm/${name}.img -i /mnt/
		read -p "输入主机名: " new_hostname
		echo "$new_hostname" > /mnt/etc/hostname
		read -p "输入主机的ip地址:" new_ip
		sed -i "/IPADDR/s/192\.168\.122\.254/$new_ip/" /mnt/etc/sysconfig/network-scripts/ifcfg-eth0
		echo "$new_ip $new_hostname" >> /mnt/etc/hosts
		sleep 1
		umount -l /mnt
	;;
	2)
		read -p "输入修改虚拟机的名字: " name
		num=`virsh list --all |awk '{print $2}' |grep "$name"|wc -l`
                read -p "输入主机名: " new_hostname
                read -p "输入主机的ip地址:" new_ip
		x=`echo $new_ip|sed -r "s/(.*)[.](.*)[.](.*)[.](.*)/\4/"`
		for ((i=1;i<=$num;i++))
		do
			final_hostname=`echo $new_hostname|sed -r "s/(.*)/\1$i.com/"`
                	guestmount -a /kvm/${name}-${i}.img -i /mnt/
                	echo "${final_hostname}" > /mnt/etc/hostname
                	sed -i "/IPADDR/s/192\.168\.122\.254/$new_ip/" /mnt/etc/sysconfig/network-scripts/ifcfg-eth0
                	echo "$new_ip ${final_hostname}" >> /mnt/etc/hosts
                	sleep 1
                	umount -l /mnt
			x=$(($x+1))
			new_ip=`echo $new_ip|sed -r "s/(.*)[.](.*)[.](.*)[.](.*)/\1.\2.\3.$x/"`
		done
	;;
	esac
}

add_hardware(){
	echo "======================"
	echo "===== 1.添加磁盘  ===="
	echo "===== 2.删除瓷蓝  ===="
	echo "===== 3.添加网卡  ===="
	echo "===== 4.删除网卡  ===="
	echo "===== 5.返回上层菜单 ="
	echo "======================"
	read -p "选择您的操作[1|2|3]: " num
	virsh list --all
	read -p "输入添加硬件的虚拟机名字: " name
	case $num in
	1)
		qemu-img create -f qcow2 /kvm/$name-new.img 2G
		virsh attach-disk $name --source /kvm/$name-new.img --target vdb --cache writeback --subdriver qcow2 --persistent 
	;;
	2)
		virsh detach-disk $name vdb --persistent
	;;
	3)
		virsh attach-interface $name --type bridge --source virbr0 --persistent	
	;;
	4)
		virsh start $name 2>/dev/null
		read -p "输入修改网卡的主机ip" oip
		ssh $oip ifconfig ens37|awk '/ether/{print $2}'
	;;
	5)
		return
	;;
	*)
		echo "输入正确操作"
	;;
	esac	
}


while true
do
	clear
	echo "========================"
	echo "====  1.创建虚拟机  ===="
	echo "====  2.启动虚拟机  ===="
	echo "====  3.查询虚拟机  ===="
	echo "====  4.停止虚拟机  ===="
	echo "====  5.删除虚拟机  ===="
	echo "====  6.修改虚拟机  ===="
	echo "====  7.添加硬件    ===="
	echo "====  8.退出        ===="
	echo "========================"
	read -p "选择您的操作[1|2|3|4|5|6|7|8]: " num
	case $num in
	1)
		create_v_host
	;;
	2)
		start_v_host
	;;
	3)
		query_v_host
	;;
	4)
		stop_v_host
	;;
	5)
		delete_v_host
	;;
	6)
		alter_v_host
	;;
	7)
		add_hardware
	;;
	8)
		break
	;;
	*)
		:
	;;
	esac
done
