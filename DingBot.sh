#!/usr/bin/env bash
# ******************************************************
# Author       	:	Tang
# Email        	:	tserialt@gmail.com
# Filename     	:	DingBot.sh
# Version      	:	v1.0
# Created Time 	:	2026-11-09 19:53
# Last modified	:	2026-11-09 00:29
# By Modified  	:
# Description  	:    send msg by dingRobot 签名版
#
# ******************************************************


dingbotSend() {
  local token="f17dfad0bf48677541257501f3a9293fb2bc94a34714de4e5cxxxxxxxx" 
  local secret="SECe08aa304847xxxxxxxxxxxxxxxxxxxxxxx" 
  local title="$1" msg="$2" ts sign
  urlencode(){ local s="$1" c i; for((i=0;i<${#s};i++));do c="${s:i:1}"; case "$c" in [a-zA-Z0-9.~_-]) printf %s "$c";; *) printf '%%%02X' "'$c";; esac; done; }
  json(){ local s="$1"; s=${s//\\/\\\\}; s=${s//\"/\\\"}; s=${s//$'\n'/\\n}; printf %s "$s"; }
  ts=$(($(date +%s)*1000))
  sign=$(urlencode "$(printf '%s\n%s' "$ts" "$secret" | openssl dgst -sha256 -hmac "$secret" -binary | base64 | tr -d '\n')")
  curl -sS -H 'Content-Type: application/json' \
    -d "{\"msgtype\":\"markdown\",\"markdown\":{\"title\":\"$(json "$title")\",\"text\":\"$(json "$msg")\"}}" \
    "https://oapi.dingtalk.com/robot/send?access_token=$token&timestamp=$ts&sign=$sign"
}
msg=$(printf '### ✅ 镜像构建成功\n\n- **镜像地址:** `%s`' "$IMAGE_TAG")
dingbotSend  "Gitea Action" "$msg"