#!/bin/bash
# ******************************************************
# Author       	:	serialt
# Email        	:	serialt@qq.com
# Filename     	:   go-build.sh
# Version      	:	v1.0
# Created Time 	:	2021-06-25 10:47
# Last modified	:	2021-06-25 10:47
# By Modified  	:
# Description  	:       build go package
#
# ******************************************************

# start go mod
export GO111MODULE=on
# set goproxy
export GOPROXY=https://goproxy.cn

## package
PROJECT_NAME="mm-wiki"
INSTALL_NAME="install"
BUILD_DIR="release"
ROOT_DIR=$(pwd)

# windows .exe
if [ "${GOOS}" = "" ]; then
    UNAME=$(command -v uname)
    case $("${UNAME}" | tr '[:upper:]' '[:lower:]') in
    msys* | cygwin* | mingw* | nt | win*)
        PROJECT_NAME=${PROJECT_NAME}".exe"
        INSTALL_NAME=${INSTALL_NAME}".exe"
        ;;
    esac
elif [ "${GOOS}" = "windows" ]; then
    PROJECT_NAME=${PROJECT_NAME}".exe"
    INSTALL_NAME=${INSTALL_NAME}".exe"
fi

rm -rf ${BUILD_DIR}
