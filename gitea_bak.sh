#!/bin/bash
# ******************************************************
# Author       	:	serialt 
# Email        	:	tserialt@gmail.com
# Filename     	:	gitea_bak.sh
# Created Time 	:	2021-10-31 21:13
# Last modified	:	2021-10-31 21:13
# Description  	: 
#  
# ******************************************************
  

# This script creates a .zip backup of gitea running inside docker and copies the backup file to the backup directory

BAK_DIR=/opt/backup/gitea

mkdir -p "${BAK_DIR}"
# This script creates a .zip backup of gitea running inside docker and copies the backup file to the backup directory

echo "Delete older backup ..."
find ${BAK_DIR} -type f -mtime +4 -name "*.zip" -delete


echo "Creating gitea backup inside docker containter ..."
docker exec -u git $(docker ps -qf "name=gitea") bash -c '/app/gitea/gitea dump -c /data/gitea/conf/app.ini --file /tmp/gitea-dump.zip'

echo "Copying backup file from the container to the host machine ..."
docker cp $(docker ps -qf "name=gitea"):/tmp/gitea-dump.zip /tmp/

echo "Removing backup file in container ..."
docker exec -u git $(docker ps -qf "name=gitea") bash -c 'rm /tmp/gitea-dump.zip'

GITEA_VERSION=`docker exec -u git $(docker ps -qf "name=gitea") bash -c 'gitea -version' | awk '{print $3}'` 

echo "Renaming backup file ..."
BACKUPFILE=${BAK_DIR}/gitea-dump-${GITEA_VERSION}-$(date +"%Y%m%d%H%M").zip
mv /tmp/gitea-dump.zip $BACKUPFILE

echo "Backup file is available: "$BACKUPFILE

echo "Done."
