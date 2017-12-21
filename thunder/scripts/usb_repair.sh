#!/bin/sh

if [ $# != 3 ];then
	echo "invalid arguments: $@"
	exit 1
fi

fstype=$1
dev_name=$2
mount_dir=$3

SOFTMODE=`fw_printenv xl_softmode |  awk -F "=" '{print $2}'`
init_env

if [ "$SOFTMODE" == "factory" ]; then

	if [ "$fstype" = "ufsd" ];then
		mount -t ufsd -o nls=utf8,nolazy,force,umask=000 $dev_name $mount_dir
                echo $mount_dir
	elif [ "$fstype" = "ufsd-sd" ];then
	        mount -t ufsd -o wb=1,ra=4M,force $dev_name $mount_dir
                echo $mount_dir
	elif [ "$fstype" = "ntfs" ];then
		ntfs-3g $dev_name $mount_dir
                echo $mount_dir
	elif [ "$fstype" = "ext4" ];then
	       	mount -t ext4 $dev_name $mount_dir
                echo $mount_dir
	elif [ "$fstype" = "ext3" ];then
		mount -t ext3 $dev_name $mount_dir
                echo $mount_dir
	elif [ "$fstype" = "vfat" ];then
		mount -t vfat -o umask=000,iocharset=utf8 $dev_name $mount_dir
                echo $mount_dir
	else
		mount -o umask=000 $dev_name $mount_dir
	fi

else


# for record the time
date

dev_basename=`basename $dev_name`
tmp_flag="/tmp/${dev_basename}-repair.flag"

if [ -f $tmp_flag ]; then
	echo "$dev_name is repairing, just exit"
	exit 0
fi

export LD_LIBRARY_PATH=/thunder/lib
export PATH=$PATH:/thunder/bin

# skip unspport fs type.
repair_flag="0"
if [ "$fstype" = "ufsd" -o "$fstype" = "ufsd-sd" -o "$fstype" = "ntfs" -o "$fstype" = "ext3" -o "$fstype" = "ext4" -o "$fstype" = "vfat" ];then
	repair_flag="1"
else
	echo "not support for $fstype repair"
fi

if [ "$repair_flag" = "0" ];then
	ubus call mnt usb_insert "{\"name\":\"$dev_basename\", \"type\":\"partion\", \"state\":\"mounted\"}"
	exit 0
fi


touch $tmp_flag

umount -f $mount_dir >/dev/null 2>&1
mount | grep $dev_name
if [ "$?" = "0" ];then
	echo "umount $dev_name fail, skip repair"
	rm -rf $tmp_flag
	ubus call mnt usb_insert "{\"name\":\"$dev_basename\", \"type\":\"partion\", \"state\":\"mounted\"}"
	exit 2
fi

ubus call mnt blink
ubus call mnt usb_insert "{\"name\":\"$dev_basename\", \"type\":\"partion\", \"state\":\"repairing\"}"
echo "do usb_repair for $dev_name ($fstype)"

if [ "$fstype" = "ufsd" ];then
	chkntfs -a -f $dev_name
	mount -t ufsd -o nls=utf8,nolazy,force,umask=000 $dev_name $mount_dir
elif [ "$fstype" = "ufsd-sd" ];then
	chkntfs -a -f $dev_name
	mount -t ufsd -o wb=1,ra=4M,force $dev_name $mount_dir
elif [ "$fstype" = "ntfs" ];then
	chkntfs -a -f $dev_name
	ntfs-3g $dev_name $mount_dir
elif [ "$fstype" = "ext4" ];then
	fsck.ext3 -p $dev_name
	mount -t ext4 $dev_name $mount_dir
elif [ "$fstype" = "ext3" ];then
	fsck.ext3 -p $dev_name
	mount -t ext3 $dev_name $mount_dir
elif [ "$fstype" = "vfat" ];then
	dosfsck -a $dev_name
	mount -t vfat -o umask=000,iocharset=utf8 $dev_name $mount_dir
else
	mount -o umask=000 $dev_name $mount_dir
	echo "unknow fs type: $fstype"
fi

rm -rf $tmp_flag
ubus call mnt usb_insert "{\"name\":\"$dev_basename\", \"type\":\"partion\", \"state\":\"mounted\"}"
fi
exit 0
