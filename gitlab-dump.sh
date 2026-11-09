#!/usr/bin/env bash
# ******************************************************
# Author       	:	Tang
# Email        	:	tserialt@gmail.com
# Version      	:	v1.0
# Created Time 	:	2026-11-09 19:53
# Last modified	:	2026-11-09 00:29
# By Modified  	:
# Description  	:    gitlab数据备份
#
# ******************************************************




### 文件轮转，超过30个的保留在 ${FILE_DIR_MOTHLY} 目录里
# FILE_DIR  $1  轮转文件所在的目录
# file_name $2  轮转文件的包含的特色字符
# file_num  $3  轮转文件要保留的个数
# flag_char $4  月备份时过滤的字符
# moth_num  $5  月备份要保留的份数

rotate(){
    set -u
    # 备份文件保留的目录
    FILE_DIR=$1
    file_name=$2
    file_num=$3
    flag_char=$4
    moth_num=$5
    # 1637346743_2021_11_19_13.12.12_gitlab_backup.tar
    #  unix时间戳   年月日    gitlab版本      

    # 周备份保留的目录
    FILE_DIR_WEEKLY="${FILE_DIR}/weekly"
    # 月备份保留的目录
    FILE_DIR_MOTHLY="${FILE_DIR}/mothly"
    # 年备份保留的目录
    FILE_DIR_YEARLY="${FILE_DIR/yearly}"
    # 确保目录存在
    #[[ ! -d ${FILE_DIR_WEEKLY} ]] && mkdir ${FILE_DIR_WEEKLY}
    [[ ! -d ${FILE_DIR_MOTHLY} ]] && mkdir ${FILE_DIR_MOTHLY}
    [[ ! -d ${FILE_DIR_YEARLY} ]] && mkdir ${FILE_DIR_YEARLY}
    cd ${FILE_DIR}/
    local list=$(ls ./*${file_name}* | grep -vx ${file_name} |  sort -nk 1 -t '_' )
    #[[ ! -d ${FILE_DIR} ]] && echo " *** dir not exits *** " && exit
    cd ${FILE_DIR}
    for item in ${list};do
        local_file_num=$(ls ./*${file_name}*  | grep -vx ${file_name} | wc -l )
        [[ ${local_file_num} -le ${file_num} ]] && break
        if [[ ${local_file_num} -gt ${file_num} ]];then
            my_flag=$(echo ${item} | awk -F'_' '{print $4}')
            if [[ $(echo ${item} | awk -F'_' '{print $4}') == ${flag_char} ]] ;then 
                mv ${item} ${FILE_DIR_MOTHLY}/
            else
                [[ ${local_file_num} -gt ${file_num} ]] && rm -rf ${item}
            fi
        fi
    done

    # 轮转每月备份
    cd ${FILE_DIR_MOTHLY}
    weekList=$(ls ./*${file_name}* | grep -vx ${file_name} |  sort -nk 1 -t '_' )

    for item in ${weekList};do
        local_file_num=$(ls ./*${file_name}*  | grep -vx ${file_name} | wc -l )
        [[ ${local_file_num} -gt ${moth_num} ]] && rm -rf ${item}
        [[ ${local_file_num} -le ${moth_num} ]] && break
    done 
    set +u   
}

rotate /root/shell_work/test2 gitlab_backup 3 01 2
