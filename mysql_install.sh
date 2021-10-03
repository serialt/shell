#!/bin/bash
groupadd -g 27 mysql &>/dev/null
useradd -u 27 -g 27 -M -s /sbin/nologin mysql &>/dev/null
curl -o /tmp/mysql.tar.gz ftp://192.168.122.15/app/mysql57.tar.gz
tar -xvf /tmp/mysql.tar.gz -C /usr/local/
chown -R mysql.mysql /usr/local/mysql
mv /etc/my.cnf /etc/my.cnf.bak &>/dev/null
rm -rf /usr/local/mysql/data
/usr/local/mysql/bin/mysqld --user=mysql --initialize --datadir=/usr/local/mysql/data &>/tmp/mypass.txt
mypass=`awk '/password/{print $NF}' /tmp/mypass.txt`
cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
chkconfig --add mysqld
cat >/etc/profile.d/mysql.sh<<EOF
MYSQL_HOME=/usr/local/mysql
PATH=\$MYSQL_HOME/bin:\$PATH
export PATH MYSQL_HOME 
EOF
cat >/etc/my.cnf<<EOF
[mysqld]
socket=/tmp/mysql.sock
[mysql]
socket=/tmp/mysql.sock
EOF
pkill mysqld
systemctl restart mysqld
/usr/local/mysql/bin/mysqladmin -S /tmp/mysql.sock -uroot -p"$mypass" password "centos"
