#!/bin/bash
#serialt serialt@qq.com
#centos7开启嵌套虚拟化


green_col='\E[0;32m'
red_col="\e[1;31m"
reset_col="\e[0m"


###输出换行
echo_red(){
        echo -e "${red_col}$1${reset_col}"
}

echo_green(){
        echo -e "${green_col}$1${reset_col}"
}


vm_check_intel=`cat /sys/module/kvm_intel/parameters/nested 2>/dev/null`
vm_check_amd=`cat /sys/module/kvm_amd/parameters/nested 2>/dev/null`

###
#检查系统是否支持嵌套虚拟函数
check_vm(){
if [ "$vm_check_intel" != "" ]
then
	if [ $vm_check_intel == 'Y' ]
	then
		:	
	else	echo_red "此系统不支持嵌套虚拟化"
		vm_flag=1
	fi
fi

}

#检查嵌套虚拟化
vm_flag=0
check_vm

if [ $vm_flag -eq 1 ]
then

	#开启嵌套虚拟化
cat << EOF > /etc/modprobe.d/kvm-nested.conf
options kvm-intel nested=1
options kvm-intel enable_shadow_vmcs=1
options kvm-intel enable_apicv=1
options kvm-intel ept=1
EOF


	#reload kvm_intel
	modprobe -r kvm_intel 2>/dev/null

	if [ $? -ne 0 ]
	then 
		for i in `virsh list  |awk '{print $2}'`
	        do  
	                virsh destroy $i &>/dev/null
	        done
		modprobe -r kvm_intel
	fi

	modprobe -a kvm_intel
fi

check_vm
if [ $vm_flag -eq 1 ]
then
	echo_red "此系统无法开启嵌套虚拟化！！！！"
	exit
	
fi


#reload kvm_amd
#modprobe -r kvm_amd
#modprobe -a kvm_amd

virsh list --all
read -p"请输入要开启嵌套虚拟化的的虚拟机名：" vm_name
sed -ri "s/custom/host-passthrough/" /etc/libvirt/qemu/${vm_name}.xml
virsh define /etc/libvirt/qemu/${vm_name}.xml &>/dev/null


echo_green "嵌套虚拟化已经开启"






 








