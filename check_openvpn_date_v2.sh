#!/usr/bin/env bash
# ******************************************************
# Author       	:	serialt
# Filename     	:	check_openvpn_date.sh
# Version      	:	v1.0
# Created Time 	:	2022-05-15 05:47
# Last modified	:	2022-05-19 21:32
# By Modified  	:
# Description  	:     检查openvpn的证书有效期
#
# ******************************************************


CRT_DIR="/etc/openvpn/easy-rsa.bak/keys"
GAPDAY=50


NOW_TIME=$(date +%Y%m%d)

for i in `ls ${CRT_DIR} | grep crt` ;do
    end_time_tmp=$(openssl x509 -in ${CRT_DIR}/$i -noout -dates | grep notAfter  | awk -F'=' '{print $2}')
    end_time=$(date -d "${end_time_tmp}" +%Y%m%d)

    gap=$(echo ${end_time} - ${NOW_TIME} )
    if [[ ${gap} -gt ${GAPDAY} ]] ;then
        echo ${i} ${end_time} 
    elif [[ ${gap} -gt 1 ]] ;then   
        echo ${i} ${end_time} 证书马上过期
    fi
done