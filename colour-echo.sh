#!/bin/bash
#serialt  serialt@qq.com
#输出文字带有颜色

green_col='\E[0;32m'
red_col="\e[1;31m"
blue_col="\e[1;34m"
reset_col="\e[0m"

###输出换行
echo_red() {
    echo -e "${red_col}$*${reset_col}"
}
echo_green() {
    echo -e "${green_col}$*${reset_col}"
}
echo_blue() {
    echo -e "${blue_col}$*${reset_col}"
}

###输出不换行
echo-red() {
    echo -en "${red_col}$*${reset_col}"
}
echo-green() {
    echo -en "${green_col}$*${reset_col}"
}
echo-blue() {
    echo -en "${blue_col}$*${reset_col}"
}
