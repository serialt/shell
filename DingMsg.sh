#!/bin/bash
# ******************************************************
# Author       	:	serialt
# Email        	:	serialt@qq.com
# Filename     	:	DingMsg.sh
# Version      	:	v1.0
# Created Time 	:	2020-09-20 19:53
# Last modified	:	2020-09-21 00:29
# By Modified  	:
# Description  	:       send msg by dingRobot
#
# ******************************************************

info='serialt'
logFile='/var/log/DingRobot/DingRobot.log'

### 创建钉钉机器人消息日志轮转
logRotate() {
    [ ! -d ${logFile%/*} ] && mkdir -p ${logFile%/*}
    [ ! -f /etc/logrotate.d/DingMsg ] && cat >/etc/logrotate.d/DingMsg <<-EOF
/var/log/DingRobot/*.log {
monthly
missingok
minsize 10M
dateext
dateformat .%Y-%m-%d
rotate 10
compress
delaycompress
notifempty
create 0640 nobody nobody 

EOF

}

#发送消息
sendMsg() {

    token='1e18ffe069052b56f5a0f8fe9b6c058373e7df7ef4xxxxxxxxxxxxxxx'
    result=$(curl -s "https://oapi.dingtalk.com/robot/send?access_token=$token" \
        -H 'Content-Type: application/json' \
        -d "{'msgtype': 'text','text': {'content': 'msg:\n$*'}}")
    [ $(echo $result | grep "errmsg.*ok") ] && echo 'send succees!'

    echo "$(date +'%Y-%m-%d %H:%M.%S') state: $result  msg: $*" >>$logFile
}

main() {
    logRotate
    sendMsg $info
}

main
