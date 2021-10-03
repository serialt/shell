#!/bin/bash
# ******************************************************
# Author       	:	serialt 
# Email        	:	serialt@qq.com
# Filename     	:	prometheus_install.sh
# Version      	:	v1.0
# Created Time 	:	2020-09-27 23:49
# Last modified	:	2020-09-27 23:49
# By Modified  	: 
# Description  	:   install prometheus server
#  
# ******************************************************


Gzip_Filepath='/usr/local/src/prometheus-2.26.1.linux-amd64.tar.gz'


installPrometheus(){
    [ ! -f $Gzip_Filepath ] && exit
    useradd  --no-create-home -s /sbin/nologin prometheus
    mkdir /etc/prometheus
    mkdir -p /var/lib/prometheus/prometheus

    tar -xf $Gzip_Filepath -C /usr/local/src/
    File_Dir=`echo $Gzip_Filepath | awk -F'.tar.gz' '{print $1}'`
    
    # 移动二进制文件
    cp -a ${File_Dir}/{prometheus,promtool} /usr/local/bin/
    chmod prometheus:prometheus /usr/local/bin/prometheus
    chmod prometheus:prometheus /usr/local/bin/promtool

    # 移动库文件和配置文件
    cp -ar  ${File_Dir}/console*  /var/lib/prometheus/
    cp -a ${File_Dir}/prometheus.yml /etc/prometheus/

    # 修改文件权限
    chown -R prometheus:prometheus /var/lib/prometheus/*

cat>/etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus Server
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
--config.file /etc/prometheus/prometheus.yml \
--storage.tsdb.path /var/lib/prometheus/prometheus/ \
--web.console.templates=/var/lib/prometheus/consoles \
--web.console.libraries=/var/lib/prometheus/console_libraries
LimitNOFILE=655350
LockPersonality=true
NoNewPrivileges=true
MemoryDenyWriteExecute=true
PrivateDevices=true
PrivateTmp=true
ProtectHome=true
RemoveIPC=true
RestrictSUIDSGID=true
SyslogIdentifier=prometheus
Restart=always

[Install]
WantedBy=multi-user.target
EOF

}


startService(){
    systemctl daemon-reload
    systemctl restart prometheus

    # firewall-cmd --zone=public --add-port=9090/tcp --permanent
    # systemctl reload firewalld
}


main(){
    installPrometheus
    startService
}

main







