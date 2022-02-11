#!/bin/bash
# ******************************************************
# Author       	:	serialt
# Email        	:	serialt@qq.com
# Filename     	:	DingMsg.sh
# Version      	:	v1.2
# Created Time 	:	2020-09-20 19:53
# Last modified	:	2020-09-22 16:21
# By Modified  	:
# Description  	:       send msg by dingRobot
#                       使用脚本前请设置钉钉机器人的安全类型，脚本支持关键字和IP
#
# ******************************************************

logFile='/var/log/DingRobot/DingRobot.log'


### 创建钉钉机器人消息日志轮转
logRotate() {

    [ ! -d ${logFile%/*} ] && mkdir -p ${logFile%/*}
    [ ! -f /etc/logrotate.d/DingMsg ] && cat >/etc/logrotate.d/DingMsg <<-EOF
/var/log/DingRobot/*.log {
monthly
missingok
dateext
dateformat .%Y-%m-%d
rotate 10
minsize 10M
compress
delaycompress
notifempty
create 0640 nobody nobody 

	EOF
}

#发送消息
sendMsg() {
    local info=$*
    token='1e18ffe069052b56f5a0f8fe9b6c058373xxxxxxxxxxxxxx'
    result=$(curl -s "https://oapi.dingtalk.com/robot/send?access_token=$token" \
        -H 'Content-Type: application/json' \
        -d "{'msgtype': 'text',
                     'text': {
                         'content': '$info'
                         }
                    }")

    [ $(echo $result | grep "errmsg.*ok") ] && echo 'send succees!'
    echo "$(date +'%Y-%m-%d %H:%M.%S') state: $result  MessagesType: text     [ text: $* ]" >>$logFile
}

SendMsgByMD() {
    local info=$1    # $info markdown的标题
    local infoMsg=$2 # $infoMsg 内容
    token='1e18ffe069052b56f5a0f8fe9b6c058373e7df7xxxxxxxxxxxxxx'
    result=$(curl -s "https://oapi.dingtalk.com/robot/send?access_token=$token" \
        -H 'Content-Type: application/json' \
        -d "{
                     'msgtype': 'markdown',
                     'markdown': {
                         'title':'$info',
                         'text': '$infoMsg'
                        },
                     'at': {
                         'atMobiles': [
                             '156xxxx8827', 
                             '189xxxx8325'
                            ], 
                         'isAtAll': true
                        }
                   }")

    [ $(echo $result | grep "errmsg.*ok") ] && echo 'send succees!'
    echo "$(date +'%Y-%m-%d %H:%M.%S') state: $result  MessagesType: markdown [ title: $info  text: $infoMsg ]" >>$logFile

}

#main()
logRotate
(sendMsg 'zabbix') &
(SendMsgByMD 'zabbix' '# send msg') &
exit 55
