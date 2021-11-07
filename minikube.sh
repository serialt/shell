#!/bin/bash
# ******************************************************
# Author       	:	serialt
# Email        	:	serialt@qq.com
# Filename     	:	minikube.sh
# Version      	:	v1.0
# Created Time 	:	2020-09-27 23:49
# Last modified	:	2020-09-27 23:49
# By Modified  	:
# Description  	:   install minikube in localhost
#
# ******************************************************

# before
set -eu

configYUM() {
    # epel repo
    curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
    sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/epel.repo

    # kubernetes repo
    cat >/etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg

EOF
    yum clean all
    yum makecache fast
}

stopFirewalld() {
    # stop and disable firewalld
    systemctl stop firewalld
    systemctl disable firewalld

    # stop and disable selinux
    local selinux_mode=$(grep '^SELINUX=' /etc/selinux/config | awk -F'=' '{print $2}')
    if [ ${selinux_mode} != "disabled" ]; then
        setenforce 0
        sed -i '/^SELINUX=/c SELINUX=disabled' /etc/selinux/config
    fi
}

configSystemctl() {
    if [ -f /etc/sysctl.d/k8s.conf ]; then

        grep "^net.bridge.bridge-nf-call-ip6tables" /etc/sysctl.d/k8s.conf &>/dev/null
        [ $? != 0 ] && echo "net.bridge.bridge-nf-call-ip6tables = 1" >>/etc/sysctl.d/k8s.conf
        grep "^net.bridge.bridge-nf-call-iptables" /etc/sysctl.d/k8s.conf &>/dev/null
        [ $? != 0 ] && echo "net.bridge.bridge-nf-call-iptables = 1" >>/etc/sysctl.d/k8s.conf
        grep "^net.ipv4.ip_forward"/etc/sysctl.d/k8s.conf &>/dev/null
        [ $? != 0 ] && echo "net.ipv4.ip_forward = 1" >>/etc/sysctl.d/k8s.conf

    else
        cat >/etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
    fi

    modprobe br_netfilter
    sysctl -p /etc/sysctl.d/k8s.conf

    # off swap space
    swapoff -a
    grep 'swap' /etc/fstab | grep -v '^#' &>/dev/null
    [ $? == 0 ] && sed -ri "/swap/s/^/#/" /etc/fstab

}

installKube() {
    MINIKUBE_VERSION='v1.18.1'
    yum -y install kubelet kubectl
    systemctl enable kubelet
    curl -Lo minikube \
        https://kubernetes.oss-cn-hangzhou.aliyuncs.com/minikube/releases/${MINIKUBE_VERSION}/minikube-linux-amd64 &&
        chmod +x minikube && sudo mv minikube /usr/local/bin/
}

initMinikube() {
    minikube start --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers --driver=none
}

main() {
    configYUM
    stopFirewalld
    configSystemctl
    installKube
    initMinikube
}

main
