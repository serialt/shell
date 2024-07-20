#!/usr/bin/env bash
# ***********************************************************************
# Description   : Blue Planet
# Author        : serialt
# Email         : tserialt@gmail.com
# Created Time  : 2023-08-11 20:49:26
# Last modified : 2023-08-11 21:34:12
# Other         : 
#               : 
#                  同步两个helm chart repo的数据,需要安装nexus-push插件
# 
# 
# ***********************************************************************


src_repo=http://nexus-src.local.com/repository/helm   
src_repo_name=local
dst_repo=http://nexus.local.com/repository/helm   
dst_repo_name=newlocal

# add repo for helm 
#helm repo add ${src_repo_name} ${src_repo}
#helm repo add ${dst_repo_name} ${dst_repo}
#helm repo update

befor_time="20211104160208"
end_time="20220328093331"


project_list=$(helm search repo ${src_repo_name} |  awk '{print $1}' | grep -v NAME | awk -F '/' '{print $2}')

for project in ${project_list} ;do 
    version_list=$(helm search repo ${src_repo_name}/${project} -l  | awk '{print $2}')
    for version in ${version_list};do 
        if [[ ${version} -gt ${befor_time} ]];then 
            if [[ ${version} -lt ${end_time} ]];then
                
                helm fetch ${src_repo_name}/${project} --version ${version}
                helm nexus-push ${dst_repo_name}  ${project}-${version}.tgz  -u uploader -p uploader
            fi
        fi    

    done 
done
