# ******************************************************
# Author       	:	serialt 
# Email        	:	serialt@qq.com
# Filename     	:	remove.sh
# Created Time 	:	2021-10-03 14:47
# Last modified	:	2021-10-03 14:47
# Description  	: rm -rf 后悔药
#  
# ******************************************************
#!/bin/bash  

setTrash(){
    trash_path="/tmp/.trash"
    crontab_job="0 0 * * 0 rm -rf /tmp/.trash/*"
    cat > /usr/local/bin/remove.sh <<EOF
#!/bin/bash
TRASH_DIR=${trash_path}  
  
[[ ! -f \${TRASH_DIR} ]] && mkdir -p \${TRASH_DIR}   
for i in \$*; do  
    STAMP=\`date "+%Y%m%d%H%M%S"\`  
    fileName=\`basename \$i\`  
    mv \$i \$TRASH_DIR/\$STAMP.\$fileName  
done
EOF
    grep 'remove.sh' /etc/bashrc &> /dev/null
    [[ $? != 0 ]] && echo 'alias rm="bash /usr/local/bin/remove.sh"' >> /etc/bashrc
    (crontab -l;echo "${crontab_job}") | crontab
    source /etc/bashrc
}

# main
    setTrash
