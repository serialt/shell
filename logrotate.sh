#!/bin/bash
# ******************************************************
# Author       	:	serialt 
# Email        	:	serialt@qq.com
# Filename     	:	logrotate.sh
# Version      	:	v1.0
# Created Time 	:	2020-09-27 23:49
# Last modified	:	2020-09-27 23:49
# By Modified  	: 
# Description  	: 
#  
# ******************************************************
  

rotate(){
    set -u
    file_dir='/root/abc/test' 
    file_name='gins_backend'
    file_num=4
    # 文件示例 gins_backend_20200927143023

    local list=`ls $file_dir | grep ${file_name} | grep -vx ${file_name} |  sort -nk 3 -t '_' `
    local num=`ls $file_dir | grep ${file_name} | wc -l`
    cd $file_dir/
    for item in $list;do
      local_file_num=`ls $file_dir | grep ${file_name} | wc -l `
      [ $local_file_num -gt $file_num ] && rm -rf ${file_dir}/${item}             
    done

    set +u   
 
}

rotate
