docker-run(){
	case $# in 
	2)
		docker run -d -e "container=docker" --privileged=true -v /sys/fs/cgroup:/sys/fs/cgroup --name $1 $2 /usr/sbin/init 
		;;
	3)
		for ((i=1;i<=$2;i++))
		do
			tmp_name=${1}${i}	
			docker run -d -e "container=docker" --privileged=true -v /sys/fs/cgroup:/sys/fs/cgroup --name $tmp_name $3 /usr/sbin/init 
		done
		;;

	*)
		echo " docker-run  容器名 [容器个数] 镜像名 "
		;;
	esac
}

docker-attach(){
docker exec -it $1 /bin/bash
}
alias docker-exec='docker-attach'


docker-start(){
	case $1 in 
	
	all)
		for i in `docker ps --all | sed "1d" | awk '{print $1}'`
		do
			docker start $i 2>/dev/null 
		done
		;;
	--help|help)
		echo " docker-start  + [ 容器名 | all ]"
		;;
	*)
			docker start $1 2>/dev/null
		;;
esac	
}

docker-stop(){
	case $1 in 
	
	all)
		for i in `docker ps |sed "1d" | awk '{print $1}'`
		do
			docker stop $i
		done
		;;
	--help|help)
		echo " docker-stop  + [ 容器名 | all ]"
		;;
	*)
		docker stop $1
		;;
esac	
}

docker-rm(){
	case $1 in 
	all)
		for i in `docker ps -qa`
		do
			docker stop $i
			docker rm $i
		done
	;;

	*) 
		docker stop $1
		docker rm $1
		;;
	esac

}
