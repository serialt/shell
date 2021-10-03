#!/bin/bash
#serialt serialt@qq.com
#openstack rokcy
#脚本在controller节点上运行
{
. /root/echo_colour.sh


ifconfig
#read -p"输入conoller节点的ip：" controller_ip

#read -p "输入computer节点的ip：" computer_ip
controller_ip=10.0.0.11
computer_ip=10.0.0.33
password=centos
echo_red "all password default [ centos ]"

######
###1、环境配置

###1.1 域名解析 
echo "${controller_ip}  controller" >>/etc/hosts
echo "${computer_ip}  computer" >>/etc/hosts
#scp /etc/hosts computer:/etc/

###1.2 update software
#yum -y install upgrade

###1.3 chrony

#controller
	yum -y install chrony
	sed -ri "6c \server controller iburst" /etc/chrony.conf
	sed -ri "26c \allow 10.0.0.0/24" /etc/chrony.conf
	systemctl restart chronyd
	systemctl enable chronyd

#computer节点
#ssh -i <<EOF
#yum -y install chrony
#sed -ri "6c \server controller iburst" /etc/chrony.conf
#systemctl restart chronyd
#systemctl enable chronyd
#EOF

###1.4 yum
#aliyun
cat << EOF > /etc/yum.repos.d/openstack-rocky.repo
[openstack-rocky]
name=openstack-rocky
baseurl=https://mirrors.huaweicloud.com/centos/7/cloud/x86_64/openstack-rocky/
enabled=1
gpgcheck=0
[qemu-kvm]
name=qemu-kvm
baseurl=https://mirrors.huaweicloud.com/centos/7/virt/x86_64/kvm-common/
enabled=1
gpgcheck=0
EOF

rm -rf /run/yum/pid
yum clean all 
yum repolist


#scp /etc/yum.repos.d/openstack-rocky.repo computer://etc/yum.repos.d/

###1.5 install openstack client and selinux
	yum install python-openstackclient openstack-selinux -y

###1.6 install mariadb
	yum install -y mariadb mariadb-server python2-PyMySQL

#modify mariadb
	echo -e "[mysqld]\nbind-address = ${controller_ip}\ndefault-storage-engine = innodb \ninnodb_file_per_table = on \nmax_connections = 4096 \ncollation-server = utf8_general_ci \ncharacter-set-server = utf8 " >/etc/my.cnf.d/openstack.cnf

#start mariadb
	systemctl restart mariadb.service
	systemctl enable mariadb.service

#init maridb
	read -p"输入任意键" input_anykey
	mysql_secure_installation	

###1.7 install rabbitmq-server
	yum -y install rabbitmq-server
	systemctl restart rabbitmq-server.service
	systemctl enable rabbitmq-server.service

#add  rabbitmq openstack user
	rabbitmqctl add_user openstack centos
#设置openstack用户最高权限
	rabbitmqctl set_permissions openstack ".*" ".*" ".*"
	
	echo-green "rabbitmq is ok! "

###1.8 install memcached
	yum -y install memcached
	sed -ri "s/127.0.0.1/$controller_ip/" /etc/sysconfig/memcached

#start memcached service
	systemctl start memcached.service
	systemctl enable memcached.service

	echo_green "memcached is ok!"

###1.9 install etcd service
	yum install etcd -y

#modify etcd 
	sed -ri '5c \ETCD_LISTEN_PEER_URLS="http://${controller_ip}:2380"' /etc/etcd/etcd.conf 
	sed -ri '6c \ETCD_LISTEN_CLIENT_URLS="http://${controller_ip}:2379"' /etc/etcd/etcd.conf
	sed -ri '9c \ETCD_NAME="controller"' /etc/etcd/etcd.conf
	sed -ri '20c \ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${controller_ip}:2380"' /etc/etcd/etcd.conf
	sed -ri '21c \ETCD_ADVERTISE_CLIENT_URLS="http://${controller_ip}:2379"' /etc/etcd/etcd.conf
	sed -ri '26c \ETCD_INITIAL_CLUSTER="controller=http://${controller_ip}:2380"' /etc/etcd/etcd.conf
	sed -ri '27c \ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"' /etc/etcd/etcd.conf
	sed -ri '28c \ETCD_INITIAL_CLUSTER_STATE="new"' /etc/etcd/etcd.conf

#start etcd
	systemctl restart etcd
	systemctl enable etcd

	echo_green "etcd is ok!"



######
###2 install keystone
#contoller node

###2.1 数据库授权
	mysql -uroot -pcentos -e "CREATE DATABASE keystone;"
	mysql -uroot -pcentos -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'centos';"
	mysql -uroot -pcentos -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'centos';"

###2.2 安装keystone
	yum install openstack-keystone httpd mod_wsgi -y

#modify
	sed -ri "741c \connection = mysql+pymysql://keystone:${password}@controller/keystone" /etc/keystone/keystone.conf
	sed -ri "2828c \provider = fernet" /etc/keystone/keystone.conf

#2.3 pip问题
	yum -y install python2-pip
#	yum -y install expect
#/usr/bin/expect << eof
#set timeout=10
#spawn	pip uninstall urllib3
#expect ""
#send ""
#spawn	pip uninstall chardet
#expect ""
#send ""
#spawn 	pip uninstall requests
#expect ""
#send ""



#eof
#	pip install --upgrade pip
	pip uninstall urllib3
	pip uninstall chardet
	pip uninstall requests
	pip install requests


#2.4同步数据
	su -s /bin/sh -c "keystone-manage db_sync" keystone


#2.5 初始化fernet key库
	keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
	keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

#2.6 引导身份认证
keystone-manage bootstrap --bootstrap-password centos \
--bootstrap-admin-url http://controller:5000/v3/ \
--bootstrap-internal-url http://controller:5000/v3/ \
--bootstrap-public-url http://controller:5000/v3/ \
--bootstrap-region-id RegionOne

#2.7 http
	sed -ri "s/#ServerName www.example.com:80/ServerName controller/" /etc/httpd/conf/httpd.conf

#创建链接文件
	ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/

#启动httpd
	systemctl restart httpd
	systemctl enable httpd

#2.8 添加环境变量脚本 admin-openrc
cat>/root/admin-openrc<<EOF
export OS_USERNAME=admin
export OS_PASSWORD=centos
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

#添加测试环境变量脚本 damo-openrc
cat>/root/damo_openrc<<EOF
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=myproject
export OS_USERNAME=myuser
export OS_PASSWORD=centos
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

#2.9 创建域，项目，用户，角色
	. /root/admin-openrc
	openstack domain create --description "An Example Domain" example
	openstack project create --domain default  --description "Service Project" service
	openstack project create --domain default --description "Demo Project" myproject
	openstack user create --domain default   --password-prompt myuser
	openstack role create myrole
	openstack role add --project myproject --user myuser myrole

#验证

unset OS_AUTH_URL OS_PASSWORD
openstack --os-auth-url http://controller:5000/v3 \
  --os-project-domain-name Default --os-user-domain-name Default \
  --os-project-name admin --os-username admin token issue

 openstack --os-auth-url http://controller:5000/v3 \
  --os-project-domain-name Default --os-user-domain-name Default \
  --os-project-name myproject --os-username myuser token issue


source /root/admin-openrc
openstack token issue


######
#3  glance project


#3.1 create database,user and grant to user
	mysql -uroot -pcentos -e "CREATE DATABASE glance;"
	mysql -uroot -pcentos -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'centos';"
	mysql -uroot -pcentos -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'centos';"


#3.2 cerate glance domain,project,user,role,
	openstack user create --domain default --password-prompt glance
	openstack role add --project service --user glance admin
	openstack service create --name glance --description "OpenStack Image" image
	openstack endpoint create --region RegionOne image public http://controller:9292
	openstack endpoint create --region RegionOne image internal http://controller:9292
	openstack endpoint create --region RegionOne  image admin http://controller:9292

#3.3 install glance
	yum install -y openstack-glance

#/etc/glance/glance-api.conf
	sed -ri "/^\[database/a \connection = mysql+pymysql://glance:centos@controller/glance" /etc/glance/glance-api.conf
	
	sed -ri "/^\[glance_store/a \filesystem_store_datadir = /var/lib/glance/images/ " /etc/glance/glance-api.conf
	sed -ri "/^\[glance_store/a \default_store = file " /etc/glance/glance-api.conf
	sed -ri "/^\[glance_store/a \stores = file,http " /etc/glance/glance-api.conf
	
	sed -ri "/^\[keystone_authtoken/a \password = centos " /etc/glance/glance-api.conf
	sed -ri "/^\[keystone_authtoken/a \username = glance " /etc/glance/glance-api.conf
	sed -ri "/^\[keystone_authtoken/a \project_name = service " /etc/glance/glance-api.conf
	sed -ri "/^\[keystone_authtoken/a \user_domain_name = Default " /etc/glance/glance-api.conf
	sed -ri "/^\[keystone_authtoken/a \project_domain_name = Default " /etc/glance/glance-api.conf
	sed -ri "/^\[keystone_authtoken/a \auth_type = password " /etc/glance/glance-api.conf
	sed -ri "/^\[keystone_authtoken/a \memcached_servers = controller:11211 " /etc/glance/glance-api.conf
	sed -ri "/^\[keystone_authtoken/a \auth_url = http://controller:5000 " /etc/glance/glance-api.conf
	sed -ri "/^\[keystone_authtoken/a \www_authenticate_uri  = http://controller:5000" /etc/glance/glance-api.conf

	sed -ri "/^\[paste_deploy/a \flavor = keystone " /etc/glance/glance-api.conf

#/etc/glance/glance-registry.conf
	sed -ri "/^\[database/a \connection = mysql+pymysql://glance:centos@controller/glance" /etc/glance/glance-registry.conf
	sed -ri "/^\[keystone_authtoken/a \password = centos" /etc/glance/glance-registry.conf
	sed -ri "/^\[keystone_authtoken/a \username = glance" /etc/glance/glance-registry.conf
	sed -ri "/^\[keystone_authtoken/a \project_name = service" /etc/glance/glance-registry.conf
	sed -ri "/^\[keystone_authtoken/a \user_domain_name = Default" /etc/glance/glance-registry.conf
	sed -ri "/^\[keystone_authtoken/a \project_domain_name = Default" /etc/glance/glance-registry.conf
	sed -ri "/^\[keystone_authtoken/a \auth_type = password" /etc/glance/glance-registry.conf
	sed -ri "/^\[keystone_authtoken/a \memcached_servers = controller:11211" /etc/glance/glance-registry.conf
	sed -ri "/^\[keystone_authtoken/a \auth_url = http://controller:5000" /etc/glance/glance-registry.conf
	sed -ri "/^\[keystone_authtoken/a \www_authenticate_uri = http://controller:5000" /etc/glance/glance-registry.conf

	sed -ri "/^\[paste_deploy/a \flavor = keystone" /etc/glance/glance-registry.conf

#3.4 sync glance database
	su -s /bin/sh -c "glance-manage db_sync" glance

#3.5 start
	systemctl start openstack-glance-api.service openstack-glance-registry.service 
	systemctl enable openstack-glance-api.service openstack-glance-registry.service

#3.6 check glance
#wget the image maybe exit network error!!!
#	source /root/admin-openrc
#	wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img

#inport image to glance database

#openstack image create "cirros" \
#--file cirros-0.4.0-x86_64-disk.img \
#--disk-format qcow2 --container-format bare \
#--public 

#check the cirros image 
#	openstack image list





######
#4 nova service
#controller

#4.1 create databeas,user and grant
	mysql -uroot -pcentos -e "CREATE DATABASE nova_api;"
	mysql -uroot -pcentos -e "CREATE DATABASE nova;"
	mysql -uroot -pcentos -e "CREATE DATABASE nova_cell0;"
	mysql -uroot -pcentos -e "CREATE DATABASE placement;"
	
mysql -uroot -pcentos -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'centos';"
mysql -uroot -pcentos -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'centos';"
mysql -uroot -pcentos -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'centos';"
mysql -uroot -pcentos -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%'  IDENTIFIED BY 'centos';"
mysql -uroot -pcentos -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost'  IDENTIFIED BY 'centos';"
mysql -uroot -pcentos -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%'  IDENTIFIED BY 'centos';"
mysql -uroot -pcentos -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost'  IDENTIFIED BY 'centos';" 
mysql -uroot -pcentos -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%'   IDENTIFIED BY 'centos';"

#4.2 create nova user and service

source /root/admin-openrc
openstack user create --domain default --password-prompt nova
openstack role add --project service --user nova admin

#Create the nova service entity
openstack service create --name nova  --description "OpenStack Compute" compute

#Create the Compute API service endpoints
openstack endpoint create --region RegionOne   compute public http://controller:8774/v2.1
openstack endpoint create --region RegionOne   compute internal http://controller:8774/v2.1
openstack endpoint create --region RegionOne   compute admin http://controller:8774/v2.1

#Create a Placement service user using your chosen PLACEMENT_PASS
openstack user create --domain default --password-prompt placement

#Add the Placement user to the service project with the admin role
openstack role add --project service --user placement admin

#Create the Placement API entry in the service catalog
openstack service create --name placement  --description "Placement API" placement

#Create the Placement API service endpoints
openstack endpoint create --region RegionOne   placement public http://controller:8778
openstack endpoint create --region RegionOne  placement internal http://controller:8778
openstack endpoint create --region RegionOne   placement admin http://controller:8778



#4.3 Install nova and configure components¶
yum install openstack-nova-api openstack-nova-conductor  \
 openstack-nova-console openstack-nova-novncproxy \
 openstack-nova-scheduler openstack-nova-placement-api -y

#Edit the /etc/nova/nova.conf
 sed -ri "/^\[DEFAULT/a \  \
\n enabled_apis = osapi_compute,metadata \
\n transport_url = rabbit://openstack:centos@controller \
\n my_ip = 10.0.0.11 \
\n use_neutron = true \
\n firewall_driver = nova.virt.firewall.NoopFirewallDriver " /etc/nova/nova.conf

sed -ri "/^\[api_database/a \connection = mysql+pymysql://nova:centos@controller/nova" /etc/nova/nova.conf
sed -ri "/^\[api_database/a \connection = mysql+pymysql://nova:centos@controller/nova_api" /etc/nova/nova.conf

sed -ri "/^\[databases/a \connection = mysql+pymysql://nova:centos@controller/nova" /etc/nova/nova.conf
sed -ri "/^\[placement_database/a \connection = mysql+pymysql://placement:centos@controller/placement" /etc/nova/nova.conf
sed -ri "/^\[api/a \auth_strategy = keystone" /etc/nova/nova.conf

sed -ri "/^\[keystone_authtoken/a \ \
\n auth_url = http://controller:5000/v3 \
\n memcached_servers = controller:11211 \
\n auth_type = password \
\n project_domain_name = default \
\n user_domain_name = default \
\n project_name = service \
\n username = nova \
\n password = centos " /etc/nova/nova.conf


sed -ri "/^\[vnc/a \server_proxyclient_address = \$my_ip" /etc/nova/nova.conf
sed -ri "/^\[vnc/a \server_listen = \$my_ip" /etc/nova/nova.conf
sed -ri "/^\[vnc/a \enabled = true" /etc/nova/nova.conf

sed -ri "/^\[glance/a \api_servers = http://controller:9292" /etc/nova/nova.conf
sed -ri "/^\[oslo_concurrency/a \lock_path = /var/lib/nova/tmp" /etc/nova/nova.conf

sed -ri "/^\[placement\]/a \ \
\n region_name = RegionOne \
\n project_domain_name = Default \
\n project_name = service \
\n auth_type = password \
\n user_domain_name = Default \
\n auth_url = http://controller:5000/v3 \
\n username = placement \
\n password = centos " /etc/nova/nova.conf

# /etc/httpd/conf.d/00-nova-placement-api.conf

sed -ri "/Listen/a \ \
\n <Directory /usr/bin> \
\n    <IfVersion >= 2.4> \
\n       Require all granted \
\n    </IfVersion> \
\n    <IfVersion < 2.4> \
\n       Order allow,deny \
\n       Allow from all \
\n    </IfVersion> \
\n </Directory> "  /etc/httpd/conf.d/00-nova-placement-api.conf

#Restart the httpd service

systemctl restart httpd

#Populate the nova-api and placement databases
su -s /bin/sh -c "nova-manage api_db sync" nova

#Register the cell0 database 
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova

#Create the cell1 cell
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova

#Populate the nova database
su -s /bin/sh -c "nova-manage db sync" nova

#Verify nova cell0 and cell1 are registered correctly
su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova


#start nova service


systemctl enable openstack-nova-api.service \
  openstack-nova-consoleauth openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service

 systemctl start openstack-nova-api.service \
  openstack-nova-consoleauth openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service

}||{exit}

exit

######computer node
yum install openstack-nova-compute
#Edit the /etc/nova/nova.conf 
sed -ri "/^\[DEFAULT/a \ \
\n enabled_apis = osapi_compute,metadata \
\n transport_url = rabbit://openstack:centos@controller \
\n my_ip = 10.0.0.33 \
\n use_neutron = true \
\n firewall_driver = nova.virt.firewall.NoopFirewallDriver " /etc/nova/nova.conf

sed -ri "/^\[api/a \auth_strategy = keystone" /etc/nova/nova.conf

sed -ri "/^\[keystone_authtoken/a \  \
\n auth_url = http://controller:5000/v3 \
\n memcached_servers = controller:11211 \
\n auth_type = password \
\n project_domain_name = default \
\n user_domain_name = default \
\n project_name = service \
\n username = nova \
\n password = centos " /etc/nova/nova.conf

sed -ri "/^\[vnc/a \ \
\n enabled = true \
\n server_listen = 0.0.0.0 \
\n server_proxyclient_address = $my_ip \
\n novncproxy_base_url = http://controller:6080/vnc_auto.html " /etc/nova/nova.conf

sed -ri "/^\[glance/a \api_servers = http://controller:9292" /etc/nova/nova.conf
sed -ri "/^\[oslo_concurrency/a \lock_path = /var/lib/nova/tmp" /etc/nova/nova.conf

sed -ri "/^\[placement/a \ \
\n region_name = RegionOne \
\n project_domain_name = Default \
\n project_name = service \
\n auth_type = password \
\n user_domain_name = Default \
\n auth_url = http://controller:5000/v3 \
\n username = placement \
\n password = centos " /etc/nova/nova.conf


#start nova service
systemctl start libvirtd.service openstack-nova-compute.service
systemctl enable libvirtd.service openstack-nova-compute.service


#controller node
#find node
 . /root/admin-openrc
openstack compute service list --service nova-compute

su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
#auto find node
#/etc/nova/nova.conf

sed -ri "/^\[scheduler/a \discover_hosts_in_cells_interval = 300 " /etc/nova/nova.conf

#验证
. /root/admin-openrc
openstack compute service list

openstack catalog list
openstack image list
nova-status upgrade check





######neutron service
#controller node

#create database,user and grant
mysql -uroot -pcentos -e "CREATE DATABASE neutron;"
mysql -uroot -pcentos -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost'   IDENTIFIED BY 'centos';"
mysql -uroot -pcentos -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%'   IDENTIFIED BY 'centos';"

openstack user create --domain default --password-prompt
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking" network

openstack endpoint create --region RegionOne network public http://controller:9696

openstack endpoint create --region RegionOne network internal http://controller:9696

openstack endpoint create --region RegionOne network admin http://controller:9696



# 4.4 Networking Option

echo_red "Networking Option"
cat<<EOF
1: Provider networks
2: Self-service networks

EOF

read network_opetion
case $network_option in 
	
1)	
	#Networking Option 1: Provider networks
	#p1 Install the components
	yum install openstack-neutron openstack-neutron-ml2  openstack-neutron-linuxbridge ebtables -y

	#p2 Configure the server component
	#Edit the /etc/neutron/neutron.conf
	sed -ri "/[database\/a \connection = mysql+pymysql://neutron:centos@controller/neutron" /etc/neutron/neutron.conf
	sed -ri "/\[DEFAULT/a \notify_nova_on_port_data_changes = true" /etc/neutron/neutron.conf
	sed -ri "/\[DEFAULT/a \notify_nova_on_port_status_changes = true" /etc/neutron/neutron.conf
	sed -ri "/\[DEFAULT/a \auth_strategy = keystone" /etc/neutron/neutron.conf
	sed -ri "/\[DEFAULT/a \transport_url = rabbit://openstack:centos@controller" /etc/neutron/neutron.conf
	sed -ri "/\[DEFAULT/a \service_plugins =" /etc/neutron/neutron.conf
	sed -ri "/\[DEFAULT/a \core_plugin = ml2" /etc/neutron/neutron.conf

	sed -ri "/\[keystone_authtoken/a \password = centos" /etc/neutron/neutron.conf
	sed -ri "/\[keystone_authtoken/a \username = neutron" /etc/neutron/neutron.conf
	sed -ri "/\[keystone_authtoken/a \project_name = service" /etc/neutron/neutron.conf
	sed -ri "/\[keystone_authtoken/a \user_domain_name = default" /etc/neutron/neutron.conf
	sed -ri "/\[keystone_authtoken/a \project_domain_name = default" /etc/neutron/neutron.conf
	sed -ri "/\[keystone_authtoken/a \auth_type = password" /etc/neutron/neutron.conf
	sed -ri "/\[keystone_authtoken/a \memcached_servers = controller:11211" /etc/neutron/neutron.conf
	sed -ri "/\[keystone_authtoken/a \auth_url = http://controller:5000" /etc/neutron/neutron.conf
	sed -ri "/\[keystone_authtoken/a \www_authenticate_uri = http://controller:5000" /etc/neutron/neutron.conf
	
	sed -ri "/\{nova/a \password = centos" /etc/neutron/neutron.conf
	sed -ri "/\{nova/a \username = nova" /etc/neutron/neutron.conf
	sed -ri "/\{nova/a \project_name = service" /etc/neutron/neutron.conf
	sed -ri "/\{nova/a \region_name = RegionOne" /etc/neutron/neutron.conf
	sed -ri "/\{nova/a \user_domain_name = default" /etc/neutron/neutron.conf
	sed -ri "/\{nova/a \project_domain_name = default" /etc/neutron/neutron.conf
	sed -ri "/\{nova/a \auth_type = password" /etc/neutron/neutron.conf
	sed -ri "/\[nova/a \auth_url = http://controller:5000" /etc/neutron/neutron.conf

	sed -ri "/\[oslo_concurrency/a \lock_path = /var/lib/neutron/tmp" /etc/neutron/neutron.conf

	#p3 Configure the Modular Layer 2 (ML2) plug-in
	#Edit the /etc/neutron/plugins/ml2/ml2_conf.ini
	sed -ri "/\[ml2/a \extension_drivers = port_security" /etc/neutron/plugins/ml2/ml2_conf.ini
	sed -ri "/\[ml2/a \mechanism_drivers = linuxbridge" /etc/neutron/plugins/ml2/ml2_conf.ini
	sed -ri "/\[ml2/a \tenant_network_types =" /etc/neutron/plugins/ml2/ml2_conf.ini
	sed -ri "/\[ml2/a \type_drivers = flat,vlan" /etc/neutron/plugins/ml2/ml2_conf.ini

	sed -ri "/\[ml2_type_flat/a \flat_networks = provider" /etc/neutron/plugins/ml2/ml2_conf.ini

	sed -ri "/\[securitygroup/a \enable_ipset = true" /etc/neutron/plugins/ml2/ml2_conf.ini
	
	#p4 Configure the Linux bridge agent
	#Edit the /etc/neutron/plugins/ml2/linuxbridge_agent.ini
	sed -ri "/\[linux_bridge/a \physical_interface_mappings = provider:ens37" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
	sed -ri "/\[vxlan/a \enable_vxlan = false " /etc/neutron/plugins/ml2/linuxbridge_agent.ini

	sed -ri "/\[securitygroup/a \firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver " /etc/neutron/plugins/ml2/linuxbridge_agent.ini
	sed -ri "/[securitygroup\/a \enable_security_group = true " /etc/neutron/plugins/ml2/linuxbridge_agent.ini
	
	#p5 Configure the DHCP agent
	#Edit the /etc/neutron/dhcp_agent.ini 
	sed -ri "/[DEFAULT\/a \enable_isolated_metadata = true" /etc/neutron/dhcp_agent.ini 
	sed -ri "/[DEFAULT\/a \dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq" /etc/neutron/dhcp_agent.ini 
	sed -ri "/[DEFAULT\/a \enable_isolated_metadata = true" /etc/neutron/dhcp_agent.ini 
	
	;;

2)
	#Networking Option 2: Self-service networks
	#s1 Install the components
	yum install -y openstack-neutron openstack-neutron-ml2  openstack-neutron-linuxbridge ebtables
	
	#s2 Configure the server component
	#Edit the /etc/neutron/neutron.conf
	sed -ri "/\[database/a \connection = mysql+pymysql://neutron:centos@controller/neutron" /etc/neutron/neutron.conf
	sed -ri "/\[DEFAULT/a \notify_nova_on_port_data_changes = true" /etc/neutron/neutron.conf
	sed -ri "/\[DEFAULT/a \notify_nova_on_port_status_changes = true" /etc/neutron/neutron.conf
	sed -ri "/\[DEFAULT/a \auth_strategy = keystone" /etc/neutron/neutron.conf
	sed -ri "/\[DEFAULT/a \transport_url = rabbit://openstack:centos@controller" /etc/neutron/neutron.conf
	sed -ri "/\[DEFAULT/a \allow_overlapping_ips = true" /etc/neutron/neutron.conf
	sed -ri "/\[DEFAULT/a \service_plugins = router" /etc/neutron/neutron.conf
	sed -ri "/\[DEFAULT/a \core_plugin = ml2" /etc/neutron/neutron.conf

	sed -ri "/\[keystone_authtoken/a \ \
	\n www_authenticate_uri = http://controller:5000 \
	\n auth_url = http://controller:5000 \
	\n memcached_servers = controller:11211 \
	\n auth_type = password \
	\n project_domain_name = default \
	\n user_domain_name = default \
	\n project_name = service \
	\n username = neutron \
	\n password = centos     " /etc/neutron/neutron.conf


	sed -ri "/\[nova/a \ \
	\n auth_url = http://controller:5000 \
	\n auth_type = password \
	\n project_domain_name = default \
	\n user_domain_name = default \
	\n region_name = RegionOne \
	\n project_name = service \
	\n username = nova \
	\n password = centos " /etc/neutron/neutron.conf

	sed -ri "/\[oslo_concurrency/a \lock_path = /var/lib/neutron/tmp" /etc/neutron/neutron.conf

	#s3 Configure the Modular Layer 2 (ML2) plug-in
	# Edit the /etc/neutron/plugins/ml2/ml2_conf.ini 

	sed -ri "/\[ml2/a \ \
	\n type_drivers = flat,vlan,vxlan \
	\n tenant_network_types = vxlan \
	\n mechanism_drivers = linuxbridge,l2population \
	\n extension_drivers = port_security " /etc/neutron/neutron.conf

	sed -ri "/\[ml2_typeflat/a \flat_networks = provider " /etc/neutron/neutron.conf
	sed -ri "/\[ml2_type_vxlan/a \vni_ranges = 1:1000" /etc/neutron/neutron.conf
	sed -ri "/\[securitygroup/a \enable_ipset = true" /etc/neutron/neutron.conf

	#s4 Configure the Linux bridge agent
	#Edit the /etc/neutron/plugins/ml2/linuxbridge_agent.ini

	sed -ri "/\[linux_bridge/a \physical_interface_mappings = provider:ens37" /etc/neutron/plugins/ml2/linuxbridge_agent.ini

	sed -ri "/\[vxlan/a \ \
	\n enable_vxlan = true \
	\n local_ip = 10.0.0.33 \
	\n l2_population = true " /etc/neutron/plugins/ml2/linuxbridge_agent.ini

	sed -ri "/\[securitygroup/a \firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
	sed -ri "/\[securitygroup/a \enable_security_group = true" /etc/neutron/plugins/ml2/linuxbridge_agent.ini

	#s5 Configure the layer-3 agent
	#Edit the /etc/neutron/l3_agent.ini 

	sed -ri "/\[DEFAULT/a \interface_driver = linuxbridge" /etc/neutron/l3_agent.ini

	#s6 Configure the DHCP agent
	#Edit the /etc/neutron/dhcp_agent.ini


	sed -ri "/\[DEFAULT/a \ \
	\n interface_driver = linuxbridge \
	\n dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq \
	\n enable_isolated_metadata = true " /etc/neutron/dhcp_agent.ini

	;;

esac

#开启系统内核支持网络桥防火墙
	modprobe bridge
	modprobe br_netfilter
	echo "net.bridge.bridge-nf-call-iptables = 1 \nnet.bridge.bridge-nf-call-ip6tables = 1" >>etc/sysctl.conf
	sysctl -p /etc/sysctl.conf



#4.5 Configure the metadata agent¶
#Edit the /etc/neutron/metadata_agent.ini
sed -ri "/\[DEFAULT/a \metadata_proxy_shared_secret = centos" /etc/neutron/metadata_agent.ini
sed -ri "/\[DEFAULT/a \nova_metadata_host = controller" /etc/neutron/metadata_agent.ini


#4.6 Configure the Compute service to use the Networking service
#Edit the /etc/nova/nova.conf
sed -ri "/\[neutron/a \metadata_proxy_shared_secret = centos"  /etc/nova/nova.conf
sed -ri "/\[neutron/a \service_metadata_proxy = true"  /etc/nova/nova.conf
sed -ri "/\[neutron/a \password = centos"  /etc/nova/nova.conf
sed -ri "/\[neutron/a \username = neutron"  /etc/nova/nova.conf
sed -ri "/\[neutron/a \project_name = service"  /etc/nova/nova.conf
sed -ri "/\[neutron/a \region_name = RegionOne"  /etc/nova/nova.conf
sed -ri "/\[neutron/a \user_domain_name = default"  /etc/nova/nova.conf
sed -ri "/\[neutron/a \project_domain_name = default"  /etc/nova/nova.conf
sed -ri "/\[neutron/a \auth_type = password"  /etc/nova/nova.conf
sed -ri "/\[neutron/a \auth_url = http://controller:5000"  /etc/nova/nova.conf
sed -ri "/\[neutron/a \url = http://controller:9696"  /etc/nova/nova.conf

#创建链接
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

#启动服务

systemctl restart openstack-nova-api.service

systemctl start neutron-server.service neutron-linuxbridge-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service 

systemctl enable neutron-server.service neutron-linuxbridge-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service

echo_red "if you select Self-service,please input 2!!!"
read ss_input
if [ $ss_input -eq 2 ]
then
	systemctl start neutron-l3-agent.service
	systemctl enable neutron-l3-agent.service
fi


##compute node
##Install the components
#yum install openstack-neutron-linuxbridge ebtables ipset
#
##Configure the common component
##Edit the /etc/neutron/neutron.conf
#
#sed -ri "/\[DEFAULT/a \auth_strategy = keystone" /etc/neutron/neutron.conf
#sed -ri "/\[DEFAULT/a \transport_url = rabbit://openstack:centos@controller" /etc/neutron/neutron.conf
#sed -ri "/\[keystone_authtoken/a \ \
#\n www_authenticate_uri = http://controller:5000 \
#\n auth_url = http://controller:5000 \
#\n memcached_servers = controller:11211 \
#\n auth_type = password \
#\n project_domain_name = default \
#\n user_domain_name = default \
#\n project_name = service \
#\n username = neutron \
#\n password = centos" /etc/neutron/neutron.conf
#
#sed -ri "/\[oslo_concurrency/a \lock_path = /var/lib/neutron/tmp" /etc/neutron/neutron.conf
#
##compute node networks option
#cat<<EOF
#please input option:
#1: provider network
#2: self-service network
#
#EOF
#
#read computer_option
#case $computer_option in 
#1)
##Configure the Linux bridge agent
##Edit the /etc/neutron/plugins/ml2/linuxbridge_agent.ini
#sed -ri "/\[linux_bridge/a \physical_interface_mappings = provider:ens37" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
#sed -ri "/\[vxlan/a \enable_vxlan = false" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
#sed -ri "/\[securitygroup/a \firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
#sed -ri "/\[securitygroup/a \enable_security_group = true" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
#
#	;;
#2)
##Networking Option 2: Self-service networks
##Configure the Linux bridge agent
##Edit the /etc/neutron/plugins/ml2/linuxbridge_agent.ini 
#
#sed -ri "/\[linux_bridge/a \physical_interface_mappings = provider:ens37" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
#
#sed -ri "/\[vxlan/a \l2_population = true" /etc/neutron/plugins/ml2/linuxbridge_agent.ini 
#sed -ri "/\[vxlan/a \local_ip = 10.0.0.33" /etc/neutron/plugins/ml2/linuxbridge_agent.ini 
#sed -ri "/\[vxlan/a \enable_vxlan = true" /etc/neutron/plugins/ml2/linuxbridge_agent.ini 
#
#sed -ri "/\[securitygroup/a \firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver" /etc/neutron/plugins/ml2/linuxbridge_agent.ini 
#sed -ri "/\[securitygroup/a \enable_security_group = true" /etc/neutron/plugins/ml2/linuxbridge_agent.ini 
#
#;;
#
#
#esac 
#
#
#
##not provider and 
##Configure the Compute service to use the Networking service
##Edit the /etc/nova/nova.conf 
#
#sed -ri "/\[neutron/a \ \
#\n url = http://controller:9696 \
#\n auth_url = http://controller:5000 \
#\n auth_type = password \
#\n project_domain_name = default \
#\n user_domain_name = default \
#\n region_name = RegionOne \
#\n project_name = service \
#\n username = neutron \
#\n password = centos "/etc/nova/nova.conf 
#
##resatrt computer service
#
#systemctl restart openstack-nova-compute.service
#
##Start the Linux bridge agent
#systemctl enable neutron-linuxbridge-agent.service
#systemctl start neutron-linuxbridge-agent.service

#验证

##openstack network agent list
#
#
#######dashboard service
##contoller node
#
#yum install -y openstack-dashboard
#
#
##编辑配置文件/etc/openstack-dashboard/local_settings
#
##
#OPENSTACK_HOST = "controller"
#ALLOWED_HOSTS = ['*', 'localhost']
#SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
#
#CACHES = {
#'default': {
#'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
#'LOCATION': 'controller:11211',
#}
#}
#
#OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % OPENSTACK_HOST
#OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True
#OPENSTACK_API_VERSIONS = {
#"identity": 3,
#"image": 2,
#"volume": 2,
#}
#
#OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "Default"
#OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"
#OPENSTACK_NEUTRON_NETWORK = {
#...
#
#'enable_router': False,
#'enable_quotas': False,
#'enable_distributed_router': False,
#'enable_ha_router': False,
#'enable_lb': False,
#'enable_firewall': False,
#'enable_vpn': False,
#'enable_fip_topology_check': False,
#}
#
#
##编辑/etc/httpd/conf.d/openstack-dashboard.conf
##WSGIApplicationGroup %{GLOBAL}
#
#
#
##启动服务
#systemctl restart httpd.service memcached.service
#
##访问
##浏览器打开10.0.0.11/dashboard
#
#######创建虚拟机
##创建provider网络
#. admin-openrc
#openstack network create --share --external --provider-physical-network provider --provider-network-type flat provider
#
#openstack subnet create --network provider --allocation-pool start=192.168.200.100,end=192.168.200.200 --dns-nameserver 114.114.114.114 --gateway 192.168.200.1 --subnet-range 192.168.200.0/24 provider
#
##测试
#openstack network list
#
#
##end provider
#
####Self-service网络
#
#openstack network create selfservice
#openstack subnet create --network selfservice  --dns-nameserver 8.8.4.4 --gateway 172.16.1.1 --subnet-range 172.16.1.0/24 selfservice
#
##创建路由
#openstack router create router
#
##创建子网接口
#openstack router add subnet router selfservice
#
##创建网关  
#openstack router set router --external-gateway provider
#
##测试
#. admin-openrc
#ip netns
#
#openstack port list --router router
#
#
##创建flavor模板
#
#
#openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano
#
#
#
##创建一个Self-service网络的虚拟机
##这里的net-id是openstack network list查看到的id
#
#
#openstack server create --flavor m1.nano --image cirros --nic net-id=1c5078e9-8dbb-47d7-976d-5ac1d8b35181 cirros 
#
#openstack server list
#












































