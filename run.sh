#!/bin/bash
#
# FUNCTION: Starts up non-root DB2 container
#

usage() {
  echo -e "Usage example: \n$0 \n\
	  [-b | --base-image] base-image-name - like ubuntu:22.04 \n\
	  [-e | --entrypoint]                 - change entrypoint to /bin/bash \n\
	  [-m | --memory] X_in_GB             - memory limit in GB \n\
	  [-c | --cpus] X                     - number of cpus \n\
	  " >&2; exit 1;
}

DIR="$(cd "$(dirname "$0")" && pwd -P)"
CONT=haribda
# read the options
TEMP=$(getopt -o heb:m:c: --long help,entrypoint,base-image:,memory:,cpus: -n "$0" -- "$@")
[ $? -ne 0 ] && { echo "Terminating..." >&2; exit 1; } 

# Just for test
#echo "$TEMP"
eval set -- "$TEMP"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -b|--base-image)
            IMAGE_BASE="$2"; shift 2;;
        -e|--entrypoint)
            ENTRYPOINT="--entrypoint=/bin/bash"; shift;;
        -m|--memory)
            MEM="$2"; shift 2;;
        -c|--cpus)
            CPU="$2"; shift 2;;
        --) shift; break;;
        -h|--help) usage; exit 1;;
        *) 
            echo "Internal error!" >&2; exit 1;;
    esac
done

# : ${IMAGE_BASE="redhat/ubi9"}
: ${IMAGE_BASE="ubuntu:22.04"}
: ${MEM="4"}
: ${CPU="4"}

IMAGE_SUFFIX="unknown"
for img in ubuntu redhat suse amazon alma rocky red-soft debian oracle astra; do
  if printf "${IMAGE_BASE?}" | grep "${img?}" &>/dev/null; then
    IMAGE_SUFFIX="${img?}"
    break
  fi
done
IMAGE=haribda/haribda-${IMAGE_SUFFIX?}

docker stop ${CONT?}
docker rm -f ${CONT?}

# --entrypoint=/bin/bash \
#    --privileged \
#    -v ${DIR?}/distrib/db2/${VRMF?}:/tmp/distrib/db2 \
#  --hostname ${HOST?} \
# In a docker network
set -x
semmsl=250
semmni=$((256*MEM))
semmns=$((semmsl*semmni))
[ ${semmns?} -lt 256000 ] && semmns=256000

# Environent variables are not accessible to the startup.service
# So, we mount .env_list to a directory where it it's sourced
docker run -itd \
    --privileged \
    -m ${MEM?}GB \
    --cpus=${CPU?} \
    --memory-swap=$((MEM+2))GB \
    --memory-swappiness=5 \
    --ulimit data=-1 \
    --ulimit nofile=65536 \
    --ulimit fsize=-1 \
    --sysctl kernel.shmmni=$((256*MEM)) \
    --sysctl kernel.shmmax=$((MEM*2**30)) \
    --sysctl kernel.shmall=$((2*MEM*2**30/$(getconf PAGESIZE))) \
    --sysctl kernel.sem="${semmsl?} ${semmns?} 32 ${semmni?}" \
    --sysctl kernel.msgmni=$((1024*MEM)) \
    --sysctl kernel.msgmax=65536 \
    --sysctl kernel.msgmnb=65536 \
    --tmpfs /run \
    --tmpfs /tmp \
    --stop-timeout 300 \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -v ${PWD?}/data/etc_postfix:/etc/postfix \
    -v ${PWD?}/data/etc_scylla:/etc/scylla \
    -v ${PWD?}/data/etc_scylla.d:/etc/scylla.d \
    -v ${PWD?}/data/var_lib_scylla:/var/lib/scylla \
    -v ${PWD?}/.env_list:/setup/utils.d/haribda.sh \
    --env-file .env_list \
    --name ${CONT?} \
    ${ENTRYPOINT} \
    ${IMAGE}
