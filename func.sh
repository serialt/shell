#!/usr/bin/env bash
# ***********************************************************************
# Description   : Blue Planet
# Author        : serialt
# Email         : tserialt@gmail.com
# Other         : 
#               : 
#             
#                   常用的环境变量函数
#            
# ***********************************************************************

################################## 
# homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=TRUE



################################## 
# go 
export GOPROXY=https://goproxy.cn,direct
export GOPATH="${HOME}/go"
export GOROOT="${HOME}"/sdk/go
export GOBIN=$GOPATH/bin
#export CGO_ENABLED="0"
export GOPRIVATE="github.com/serialt,local.com"
export GOINSECURE=local.com
export PATH=$HOME/bin:$GOROOT/bin:$GOBIN:$PATH

# go 多版本切换
# gvm 1.22.5
# gvm 1.22.4
gvm(){
MY_GO_VERSION=$1
cd "${HOME}"/sdk

[[ -d "${HOME}"/sdk/go${MY_GO_VERSION} ]] 
if [[ $? -ne 0 ]]; then 
    go install golang.org/dl/go${MY_GO_VERSION}@latest &>/dev/null
    go${MY_GO_VERSION} download   &>/dev/null
fi
ln -snf "${HOME}"/sdk/go${MY_GO_VERSION} "${HOME}"/sdk/go
}

################################## 
# maven
export MAVEN_HOME="${HOME}/apache-maven"
export PATH=$PATH:$MAVEN_HOME/bin 

# java 
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
export CPPFLAGS="-I/opt/homebrew/opt/openjdk@17/include"


################################## 
# ansible
export ANSIBLE_HOME="/opt/homebrew/Cellar/ansible/9.4.0"
export PATH=$ANSIBLE_HOME/bin:$PATH


################################## 
# bash terminal

#export PS1='[\u@\h \W]\$ '
export  PS1="[\u@\h \W]🐳 "
export CLICOLOR=1
export LSCOLORS=ExGxFxdaCxDaDahbadeche
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8


# 加载bash-completion
export BASH_COMPLETION_COMPAT_DIR="/opt/homebrew/etc/bash_completion.d"
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"

# mac 上使用ll命令
alias ll='ls -l'
alias lh='ls -lh'


################################## 
# terminal history 
#UserIP=$(who -u am i | cut -d"("  -f 2 | sed -e "s/[()]//g")
export HISTTIMEFORMAT="[%F %T] [`whoami`] "
export HISTSIZE=99999999999
shopt -s histappend
PROMPT_COMMAND='history -a'



##################################
# kubeconfig

function k3s(){
    unset KUBECONFIG
    export KUBECONFIG=~/.kube/k3s
    kubectl cluster-info
    kubectl get namespace
}



################################## 
# socket5 
set-proxy(){
export http_proxy="http://127.0.0.1:8888"
export https_proxy="http://127.0.0.1:8888"  
}

no-proxy(){
unset http_proxy
unset https_proxy 
}

proxy(){
# 读取特定的配置文件
v2rayHome="${HOME}/Desktop/v2"
configFile=$1
export http_proxy="http://127.0.0.1:8888"
export https_proxy="http://127.0.0.1:8888"  

# 设置代理
networksetup -setwebproxy Wi-Fi 127.0.0.1 8888
networksetup -setsecurewebproxy Wi-Fi 127.0.0.1 8888
#networksetup -setsocksfirewallproxy Wi-Fi 127.0.0.1 5888

# 打开系统代理
networksetup -setwebproxystate Wi-Fi on
networksetup -setsecurewebproxystate Wi-Fi on
#networksetup -setsocksfirewallproxystate Wi-Fi on

case $configFile in
    hk|sg)      
        cd ${v2rayHome} && ${v2rayHome}/v2ray -c config-${configFile}.json
        ;;
    v5)
        cd ${v2rayHome} && ${v2rayHome}/v5/v2ray run -c config-v5.json  -format jsonv5
        ;;
    *)
        cd ${v2rayHome} && ${v2rayHome}/v2ray -c config-sg2.json
        ;;
esac

}

noproxy(){
unset http_proxy
unset https_proxy 
networksetup -setwebproxystate Wi-Fi off
networksetup -setsecurewebproxystate Wi-Fi off
networksetup -setsocksfirewallproxystate Wi-Fi off

PID=`ps -ef | grep v2ray | grep -v grep | awk '{print $2}'`

if [ ! -z ${PID} ];then 
    kill -9 ${PID}
fi

}




################################## 
# 查看证书信息
checkssl(){
    file=$1
    openssl x509  -noout -text -in ${file}
}


