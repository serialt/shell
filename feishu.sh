#!/usr/bin/env bash
# ***********************************************************************
# Description   : IMAU of Serialt
# Version       : 0.1
# Author        : serialt
# Email         : serialt@qq.com
# Github        : https://github.com/serialt
# Created Time  : 2022-02-10 11:34:11
# Last modified : 2022-02-11 17:53:14
# FilePath      : /shell/feishu.sh
# Other         : send msg by feishu robot
#               : 使用脚本前请设置飞书机器人的安全类型，脚本支持关键字和IP
# 
# 
#                 人和代码，有一个能跑就行
# 
# 
# ***********************************************************************



logFile='/var/log/feishu.log'

### 创建钉钉机器人消息日志轮转
logRotate() {

    [ ! -d ${logFile%/*} ] && mkdir -p ${logFile%/*}
    [ ! -f /etc/logrotate.d/feishu ] && cat >/etc/logrotate.d/feishu <<-EOF
/var/log/feishu.log {
monthly
missingok
dateext
dateformat .%Y-%m-%d
rotate 10
minsize 50M
compress
delaycompress
notifempty
create 0640 nobody nobody 

	EOF
}

# 发送 text，content中不能有空格，不支持\n换行
sendMsg(){
    local content=$*
    token='575bf7af-738e-491d-9c96-15f1b4128620'
    result=$(curl -X POST https://open.feishu.cn/open-apis/bot/v2/hook/${token} \
            -H "Content-Type: application/json" \
            -d '{"msg_type":"text","content":{"text":"'msg:\ \ ${content}'"}}'  )
    [ $(echo $result | grep "errmsg.*ok") ] && echo 'send succees!'
    echo "$(date +'%Y-%m-%d %H:%M.%S') state: $result  MessagesType: text     [ text: $* ]" >>$logFile
}




#发送消息，content中不能有空格，支持\n换行
sendPostMsg() {
    local content="my\n\n\nname-serialt"
    token='575bf7af-738e-491d-9c96-15f1b4128620'

    result=$(curl -X POST \
    https://open.feishu.cn/open-apis/bot/v2/hook/${token} \
    -H 'Content-Type: application/json' \
    -d '{
        "msg_type": "post",
        "content": {
            "post": {
                "zh_cn": {
                    "title": "msg",
                    "content": [
                        [
                            {
                                "tag": "text",
                                "un_escape": true,
                                "text": "'$content'"
                            }
                        ],
                        [

                        ]
                    ]
                }
            }
        }
    }')

    [ $(echo $result | grep "errmsg.*ok") ] && echo 'send succees!'
    echo "$(date +'%Y-%m-%d %H:%M.%S') state: $result  MessagesType: post     [ text: $* ]" >>$logFile
}


#main()
logRotate
sendPostMsg "zabbix-msg"
# (SendMsgByMD 'zabbix' '# send msg') &
exit 55

