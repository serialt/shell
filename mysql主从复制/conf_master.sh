#!/bin/bash
sed -i '/mysqld/a server-id=1' /etc/my.cnf
sed -i '/server/a log-bin=master' /etc/my.cnf
sed -i '/log-bin/a log-bin-index=master' /etc/my.cnf
systemctl restart mysqldd
/usr/local/mysql/bin/mysql -u root -p123 -e "grant replication slave on *.* to slave identified by '123'"
