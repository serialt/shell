#!/usr/bin/env bash
# ***********************************************************************
# Description   : Blue Planet
# Author        : serialt
# Email         : tserialt@gmail.com
# Created Time  : 2023-10-19 11:34:22
# Last modified : 2023-10-19 13:04:15
# FilePath      : /shell/DingMsg3.sh
# Other         : 
#               : 
#             
#                   钉钉机器人签名
#            
# ***********************************************************************



## 钉钉机器人配置
dingbot_secret='SECa87a39d5b80e32426d61xxxxxxxxxxx'
dingbot_url='https://oapi.dingtalk.com/robot/send?access_token=cd316d9df306852b6da7d1007d8xxxxxxxxxx'
## secret_type keywords || sign
ding_secret_type='sign'
## 需要艾特的人的手机号码，以空格隔开
atMobiles=(13346732245 13346732475)

## encode url
function url_encode() {
t="${1}"
if [[ -n "${1}" && -n "${2}" ]];then
  if ! echo 'xX' | grep -q "${t}";then
    t='x'
  fi
  echo -n "${2}" | od -t d1 | awk -v a="${t}" '{for (i = 2; i <= NF; i++) {printf(($i>=48 && $i<=57) || ($i>=65 &&$i<=90) || ($i>=97 && $i<=122) ||$i==45 || $i==46 || $i==95 || $i==126 ?"%c" : "%%%02"a, $i)}}'
else
  echo -e '$1 and $2 can not empty\n$1 ==> 'x' or 'X', x ==> lower, X ==> toupper.\n$2 ==> Strings need to url encode'
fi
}

## Dingbot
function dingbot(){
send_strs="${1}"
new_url="${dingbot_url}"
at_who=''
for i in ${atMobiles[*]}
do
  if [ -n "${at_who}" ];then
    at_who="${at_who},\"${i}\""
  else
    at_who="\"${i}\""
  fi
done
if [ "${ding_secret_type}" == 'keywords' ];then
  curl -s -X POST -H 'Content-Type: application/json' "${new_url}" \
-d "{\"at\":{\"atMobiles\":[${at_who}]},\"msgtype\":\"text\",\"text\":{\"content\":\"${send_strs}\"}}"
elif [ "${ding_secret_type}" == 'sign' ];then
  timestamp=$(date "+%s%3N")
  dingbot_sign=$(echo -ne "${timestamp}\n${dingbot_secret}" | openssl dgst -sha256 -hmac "${dingbot_secret}" -binary | base64)
  dingbot_sign=$(url_encode 'X' "${dingbot_sign}")
  post_url="${dingbot_url}&timestamp=${timestamp}&sign=${dingbot_sign}"
  curl -s -X POST -H 'Content-Type: application/json' "${post_url}" \
  -d "{\"at\":{\"atMobiles\":[${at_who}]},\"msgtype\":\"text\",\"text\":{\"content\":\"${send_strs}\"}}"
else
  echo "secret_type 未知，请检查配置"
fi
}
dingbot "hello"