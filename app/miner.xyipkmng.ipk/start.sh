#!/bin/sh

MAIN_EXE='xyipk'
base_path=$(dirname $0)
cd ${base_path}

SOFTMODE=`fw_printenv xl_softmode |  awk -F "=" '{print $2}'`

stop_app () 
{
    ps | grep xyipk_daemon | grep -v grep | awk '{print $1}' | xargs kill -9
    killall xyipkd
    killall ${MAIN_EXE}
}

start_app () 
{
    cd ${base_path}
    
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${base_path}/lib
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/thunder/lib
    rm ${base_path}/xyipkd -f
    sh ${base_path}/xyipk_daemon.sh &
}

XYIPK_DELAY_FLAG=/app/.need_delay
check_delay()
{
    if [ -f $XYIPK_DELAY_FLAG ]; then
        sleep 300
        rm $XYIPK_DELAY_FLAG
    fi
}

# mounting '/app' dir of rootfs to '/dev/data'
mount_app_dir()
{
    mount_dev="/dev/data"
    mount_info=`mount | grep '/dev/data'`
    
    if [ -z "$mount_info" ]; then
      mount $mount_dev /app
      # fail to mount,supposed to format
      if [ $? -ne 0 ]; then
        mkfs.ext4 -F $mount_dev
        mkdir -p /tmp/app
        mount $mount_dev /tmp/app
          if [ $? -eq 0 ]; then
	    while true
	    do
		mkdir -p /app/lost\+found/
           	cp -rf /app/* /tmp/app
	    	sync

	    	diff -r /app /tmp/app
		[ $? -eq 0 ] && break
		touch /tmp/loopcopy.app
		sleep 1
            done
	    umount $mount_dev
            mount $mount_dev /app
          fi
      else
	# mount success,do copy-action guarantee
	if [ ! -f "/app/.app_copy_ok" ]; then
            echo "do app data copy" >> /tmp/fsck_dev_data.log
            mkdir -p /tmp/system
            mount -o ro /dev/system /tmp/system

            diff -r /app /tmp/system/app
		if [ $? -ne 0 ]; then
			cp -rf /tmp/system/app/* /app
			sync
			touch /tmp/repair.app
		fi
		umount /tmp/system
        touch /app/.app_copy_ok
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
      [ -e /app/system/$plugin_dir/start.sh ] && (sh /app/system/$plugin_dir/start.sh >/dev/null 2>/dev/null &) 	
      sleep 1
  done
}

[ -d /tmp/.opkg_ipk ] || mkdir /tmp/.opkg_ipk
check_delay
stop_app
mount_app_dir

# don't bootup plugins when factory mode
[ "$SOFTMODE" = "factory" ] && exit 1

start_app
sleep 1
start_plugin_app

exit 0


