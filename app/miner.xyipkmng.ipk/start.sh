#!/bin/sh

MAIN_EXE='xyipkd'
base_path=$(dirname $0)
cd ${base_path}


stop_app () 
{
    ps | grep check_xyipkmng | grep -v grep | awk '{print $1}' | xargs kill -9
    killall ${MAIN_EXE}
}

start_app () 
{
    cd ${base_path}
    
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${base_path}/lib
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/thunder/lib
    for EXE in ${MAIN_EXE}
    do 
        echo ${EXE}
        pid=`ps | grep ${EXE} | grep -v grep | awk '{print $1}'`
        if [ "$pid" ]; then
            echo $pid
            kill -9 $pid
            cd ${base_path}
            (ulimit -v 51200 ;ulimit -c unlimited;ulimit -s 1024; ./${EXE}  ) &
        else
            echo "no prosess running"
            #kill -9 $pid
            cd ${base_path}
            (ulimit -v 51200 ;ulimit -c unlimited; ulimit -s 1024;./${EXE} ) &
        fi
    done
    sh ${base_path}/check_xyipkmng.sh &
}

# mounting '/app' dir of rootfs to '/dev/data'
mount_app_dir()
{
    mount_dev="/dev/data"
    mount_info=`mount | grep '/dev/data'`
    
    if [ -z "$mount_info" ]; then
      mount $mount_dev /app
      if [ $? -ne 0 ]; then
        mkfs.ext4 -F $mount_dev
        mkdir -p /tmp/app
        mount $mount_dev /tmp/app
          if [ $? -eq 0 ]; then
            cp -rf /app/* /tmp/app
            umount $mount_dev
            mount $mount_dev /app
          fi
      fi
        
      return 1  
    fi

    return 0
}

# boot every app in dirs named templated 'miner.<$name>.ipk' under '/app/system'
start_plugin_app ()
{
  plugin_dirs=`ls /app/system | grep miner | grep -v miner.xyipkmng.ipk`

  for plugin_dir in $plugin_dirs
  do
    [ -e /app/system/$plugin_dir/start.sh ] && sh /app/system/$plugin_dir/start.sh & 	
    sleep 1
  done
}

[ -d /tmp/.opkg_ipk ] || mkdir /tmp/.opkg_ipk
stop_app
mount_app_dir

start_app
sleep 1
start_plugin_app

exit 0


