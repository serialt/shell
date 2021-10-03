#!/bin/bash
# *********************************************************
# Author       	:	serialt 
# Email        	:	serialt@qq.com
# Filename     	:	echo_color
# Version      	:	v1.0
# Created Time 	:	2020-11-30 16:08
# Last modified	:	2020-11-30 16:08
# By Modified  	: 
# Description  	: 输出文字带有颜色
#				
#					
#  
# *********************************************************


###输出换行
echo_red(){
  echo -e "${red_col}$1${reset_col}"
}

echo_green(){
  echo -e "${green_col}$1${reset_col}"
}

echo_blue(){
  echo -e "${blue_col}$1${reset_col}"
}


###输出不换行
echo-red(){
  echo -en "${red_col}$1${reset_col}"
}

echo-green(){
  echo -en "${green_col}$1${reset_col}"
}

echo-blue(){
  echo -en "${blue_col}$1${reset_col}"
}






