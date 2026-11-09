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
gvm() {
    local sdk_dir="${HOME}/sdk"
    [[ -d "$sdk_dir" ]] || mkdir -p "$sdk_dir"

    # 1. 无参数：自动查找并切换到本地已安装的最高版本
    if [[ $# -eq 0 ]]; then
        local latest_dir
        latest_dir=$(find "$sdk_dir" -maxdepth 1 -type d -name "go[0-9]*" 2>/dev/null | sort -V | tail -n1)

        if [[ -z "$latest_dir" ]]; then
            echo "Error: No Go installations found in $sdk_dir"
            echo "Tip: Run 'gvm latest' to download the latest official Go release."
            return 1
        fi

        local latest_version
        latest_version=$(basename "$latest_dir" | sed 's/^go//')

        ln -snf "$latest_dir" "$sdk_dir/go"
        echo "Switched to latest installed Go version: go${latest_version}"
        return 0
    fi

    # 2. 处理子命令
    case "$1" in
    "list"|"ls")
        local current_target=""
        [[ -L "$sdk_dir/go" ]] && current_target=$(readlink "$sdk_dir/go")

        echo "Installed Go versions:"
        local found=0
        for dir in "$sdk_dir"/go[0-9]*/; do
            [[ -d "$dir" ]] || continue
            found=1
            local ver_num
            ver_num=$(basename "$dir" | sed 's/^go//')

            if [[ "$dir" == "${current_target}/" || "$dir" == "${current_target}" ]]; then
                echo "  * ${ver_num} (active)"
            else
                echo "    ${ver_num}"
            fi
        done
        [[ $found -eq 0 ]] && echo "  (none)"
        ;;

    "latest"|"install-latest"|"update")
        echo "Fetching the latest official Go release version..."
        
        # 1. 尝试通过官方 API 获取最新 stable 版本号
        local remote_version=""
        if command -v curl &>/dev/null; then
            remote_version=$(curl -s "https://go.dev/dl/?mode=json" | grep -o '"version": "go[0-9.]*"' | head -n1 | cut -d'"' -f4)
        elif command -v wget &>/dev/null; then
            remote_version=$(wget -qO- "https://go.dev/dl/?mode=json" | grep -o '"version": "go[0-9.]*"' | head -n1 | cut -d'"' -f4)
        fi

        # 移除 'go' 前缀
        remote_version="${remote_version#go}"

        if [[ -z "$remote_version" ]]; then
            echo "Error: Failed to fetch the latest Go version from go.dev."
            echo "Please check your network/proxy connection, or specify a version manually (e.g. gvm 1.22.5)."
            return 1
        fi

        echo "Latest official Go version is go${remote_version}."
        
        # 2. 递归调用自身去切到/下载该最新版本
        gvm "$remote_version"
        ;;

    "rm"|"remove"|"del")
        if [[ -z "$2" ]]; then
            echo "Usage: gvm rm <version>"
            return 1
        fi

        local target_version="${2#go}"
        local target_dir="${sdk_dir}/go${target_version}"

        if [[ ! -d "$target_dir" ]]; then
            echo "Error: Go version go${target_version} is not installed."
            return 1
        fi

        # Check if target version is currently active
        local current_target=""
        [[ -L "$sdk_dir/go" ]] && current_target=$(readlink "$sdk_dir/go")
        local is_active=0
        if [[ "$target_dir" == "${current_target}/" || "$target_dir" == "${current_target}" ]]; then
            is_active=1
        fi

        echo "Removing go${target_version}..."

        # 1. Remove version main directory using \rm
        \rm -rf "$target_dir"

        # 2. Clean up download launcher binary in GOPATH/bin (if any)
        if command -v go &>/dev/null; then
            local gopath_bin
            gopath_bin=$(go env GOPATH 2>/dev/null)/bin
            \rm -f "${gopath_bin}/go${target_version}"
        fi

        # 3. Clean up leftover archives in ~/sdk
        \rm -f "${sdk_dir}/go${target_version}.tar.gz" "${sdk_dir}/go${target_version}.zip" 2>/dev/null

        echo "Successfully removed go${target_version}."

        # 4. If active version was removed, re-evaluate symlink
        if [[ $is_active -eq 1 ]]; then
            echo "Active version was removed. Re-evaluating symlink..."
            local remaining_latest
            remaining_latest=$(find "$sdk_dir" -maxdepth 1 -type d -name "go[0-9]*" 2>/dev/null | sort -V | tail -n1)

            if [[ -n "$remaining_latest" ]]; then
                local next_ver
                next_ver=$(basename "$remaining_latest" | sed 's/^go//')
                ln -snf "$remaining_latest" "$sdk_dir/go"
                echo "Auto-switched to latest remaining version: go${next_ver}"
            else
                \rm -f "$sdk_dir/go"
                echo "No Go versions left. Active symlink removed."
            fi
        fi
        ;;

    *)
        local target_version="${1#go}"
        local target_dir="${sdk_dir}/go${target_version}"

        # Download automatically if not present locally
        if [[ ! -d "$target_dir" ]]; then
            echo "Version go${target_version} not found locally. Downloading..."
            if ! command -v go &>/dev/null; then
                echo "Error: 'go' binary is required in PATH to download new versions."
                return 1
            fi

            if go install "golang.org/dl/go${target_version}@latest" && "go${target_version}" download; then
                # Clean up temporary launcher binary
                local gopath_bin
                gopath_bin=$(go env GOPATH 2>/dev/null)/bin
                \rm -f "${gopath_bin}/go${target_version}"
            else
                echo "Error: Failed to download go${target_version}"
                return 1
            fi
        fi

        ln -snf "$target_dir" "$sdk_dir/go"
        echo "Successfully switched to go${target_version}"
        ;;
    esac
}


################################## 
# maven
export MAVEN_HOME="${HOME}/apache-maven"
export PATH=$PATH:$MAVEN_HOME/bin 

# java 
export JAVA_HOME=/Users/serialt/sdk/jdk/Contents/Home
export PATH="${JAVA_HOME}/bin:$PATH"


################################## 
# android
if [ -z "${JAVA_HOME:-}" ]; then
  printf '%s\n' "Error: JAVA_HOME is not set" >&2
  return 1 2>/dev/null || exit 1
fi

if [ ! -x "${JAVA_HOME}/bin/java" ]; then
  printf '%s\n' "Error: JAVA_HOME does not contain an executable bin/java: ${JAVA_HOME}" >&2
  return 1 2>/dev/null || exit 1
fi

export JAVA_HOME
export ANDROID_HOME="${ANDROID_HOME:-${HOME}/Library/Android/sdk}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME}}"

if [ -z "${ANDROID_NDK_HOME:-}" ]; then
  ANDROID_NDK_HOME=$(find "${ANDROID_SDK_ROOT}/ndk" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -V | tail -1)
fi
export ANDROID_NDK_HOME

export PATH="${JAVA_HOME}/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/emulator:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${PATH}"

if [ -z "${ANDROID_NDK_HOME}" ] || [ ! -d "${ANDROID_NDK_HOME}" ]; then
  printf '%s\n' "Warning: Android NDK was not found under ${ANDROID_SDK_ROOT}/ndk" >&2
fi



################################### 
# postgresql
#export PG_HOME="/opt/homebrew/Cellar/postgresql@14/14.6_1"
export PG_HOME="/opt/homebrew/Cellar/postgresql@14/14.12"
export PATH=$PG_HOME/bin:$PATH



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

# for kubectl ,alias k
alias k=kubectl
complete -o default -F __start_kubectl k
[ -f ~/.kubectl_aliases ] && source ~/.kubectl_aliases

function k3s(){
    unset KUBECONFIG
    export KUBECONFIG=~/.kube/k3s
    kubectl cluster-info
    kubectl get namespace
}

ki() {
    NAMESPACE=$2
    kubectl get pods -n ${NAMESPACE}  --kubeconfig="${KUBECONFIG_FILE}" -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.image}{"\t"}{.metadata.labels.app\.kubernetes\.io/instance}{"\n"}{end}{end}' |     sort -u
}


helmv() {
    NAMESPACE=$2
    helm list -n ${NAMESPACE} | awk '{print $9,$10}'
}

kv() {
    NAMESPACE=$2
    kubectl get pods -n ${NAMESPACE} --kubeconfig=${KUBECONFIG}   -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.image}{" "}{end}{"\t"}{.metadata.labels.app\.kubernetes\.io/instance}{"\n"}{end}' |uniq | awk '{$1=$1; print}' | awk -F'/' '{print $3}' | awk '{printf ("%-30s  %s\n") ,$2,$1}'  | awk -F':' '{printf ("%-57s  %s\n") ,$1,$2}' | grep -v 'docker.io' | sort

}

kb() {
    NAMESPACE=$*
    sudo kubefwd svc -c ${KUBECONFIG}  ${NAMESPACE}
}

skopeo-list(){
    local image=$1
    local default_registry="registry.cn-hangzhou.aliyuncs.com/serialt"

    # If image has no '/' (just a name), or doesn't look like a full address, prepend default registry
    if [[ "$image" != */* ]]; then
        image="docker://${default_registry}/${image}"
    elif [[ "$image" != docker://* && "$image" != *.*/* && "$image" != localhost* ]]; then
        # Has a slash but no registry host (e.g. "library/nginx") -> treat as incomplete
        image="docker://${default_registry}/${image}"
    else
        # Already a complete address (has registry host)
        [[ "$image" != docker://* ]] && image="docker://${image}"
    fi

    skopeo list-tags "$image"
}




################################## 
# terminal history 
#UserIP=$(who -u am i | cut -d"("  -f 2 | sed -e "s/[()]//g")
export HISTTIMEFORMAT="[%F %T] [`whoami`] "
export HISTSIZE=99999999999
shopt -s histappend
PROMPT_COMMAND='history -a'

alias ll='ls -l'
alias lh='ls -lh'


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


################################## 
# terraform
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"



################################## 
# go build target
linux-arm64(){
    export GOOS=linux
    export GOARCH=arm64
}
linux-amd64(){
    export GOOS=linux
    export GOARCH=amd64
}
win-amd64(){
    export GOOS=windows
    export GOARCH=amd64
}
mac-amd64(){
    export GOOS=darwin
    export GOARCH=amd64  
}
mac-arm64(){
    export GOOS=darwin
    export GOARCH=arm64  
}


################################## 
# alias rm
#alias rm="bash ${HOME}/go/bin/remove.sh"


#发送消息
dingbot(){
    info=$1
    token=c51092df7e58449000218c09dac6daf2133xxxxxxxxxxxxx
    curl -s "https://oapi.dingtalk.com/robot/send?access_token=$token" \
        -H 'Content-Type: application/json' \
   		-d "{'msgtype': 'text','text': {'content': 'msg:\n$*'}}"
}

bot() {
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

bot  "Action" "$msg"
