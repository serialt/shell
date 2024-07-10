#!/usr/bin/env bash


. images.sh
# images.sh
#!/usr/bin/env bash
# imageList=(
# swr.cn-east-3.myhuaweicloud.com/serialt/alpine:3.16=docker.local.com/library/alpine:3.16
# )

for imageName  in ${imageList[@]}
do
    SRC_IMAGE=`echo ${imageName} | awk -F '=' '{print $1}' `
    DST_IMAGE=`echo ${imageName} | awk -F '=' '{print $2}' `
    docker pull ${SRC_IMAGE}
    docker tag  ${SRC_IMAGE} ${DST_IMAGE}
    docker push  ${DST_IMAGE}
    # docker rmi  ${DEST_REPO}/${imageName}
done
