#!/bin/bash
sed -i '/mysqld/a server-id=2' /etc/my.cnf
pkill mysqld
systemctl restart mysqldd
posfile=`ssh 10.10.3.122 "/usr/local/mysql/bin/mysql -u root -p123 -e 'show master status\G'" 2>/dev/null | awk '/File/{print $NF}'`
pos=`ssh 10.10.3.122 "/usr/local/mysql/bin/mysql -u root -p123 -e 'show master status\G'" 2>/dev/null | awk '/Position/{print $NF}'`

/usr/local/mysql/bin/mysql -u root -p123 -e "change master to master_host='10.10.3.122',master_user='slave',master_password='123',master_port=3306,master_log_file='$posfile',master_log_pos=$pos;"
/usr/local/mysql/bin/mysql -u root -p123 -e "start slave;"
