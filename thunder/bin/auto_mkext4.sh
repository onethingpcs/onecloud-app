#!/bin/sh

function check_running_instance()
{
    running_count=`ps -a |grep "{auto_mkext4.sh}" | grep -v grep | wc -l`
    echo "running_count: $running_count"
    if [ "$running_count" -gt 2 ];then
        echo "there are at least one more instance running! now exit!"
        exit 1
    fi
}

function ask_for_confirmation()
{
    if [ -n "$1" ]; then
        read -p "do you really want to format disk:$1?[y/n]" confirm
    else
        read -p "do you really want to format all disks?[y/n]" confirm
    fi

    if [ $confirm = y -o $confirm = Y ];then
        return 0
    fi

    echo "cancel..."
    exit 1
}

function mkfs_ext4_partition()
{
    dev_path=$1
    echo "formatting partition ${dev_path}1 ..."
    mkfs.ext4 ${dev_path}1 << EOF
y
EOF
    if [ "$?" = "0" ];then
        return 0
    else
        return 1
    fi 
}

function parted_partition()
{
    dev_path=$1
    echo "dev_path is $dev_path" 
    parted $dev_path -s mklabel msdos mkpart primary 0% 100%
    if [ "$?" = "0" ];then
        return 0
    else
        return 1
    fi 
}

function format_partition_()
{
    dev_path=$1
    i=0

    while [ $i -lt 20 ]
    do
        echo "try to mkfs for partition ${dev_path}1 for $i times!"
        mkfs_ext4_partition $1

        if [ "$?" = "0" ];then
            echo "mkfs for partition ${dev_path}1 success!"
            return 0
        else
            echo "mkfs for partition ${dev_path}1 failed for $i time! try again in 5 seconds later"
            sleep 5
        fi

        let i++

    done

    return 1
}

function create_partition_()
{
    dev_path=$1
    i=0

    while [ $i -lt 20 ]
    do
        echo "try to create partition ${dev_path}1 for $i times!"
        parted_partition $1

        if [ "$?" = "0" ];then
            echo "create partition ${dev_path}1 success!"
            return 0
        else
            echo "create partition ${dev_path}1 failed for $i time! try again in 5 seconds later"
            sleep 5
        fi

        let i++
    done

    return 1
}

function umount_all_partition()
{
    for i in `ls /dev/sd*`
    do
        mount |grep "$i "
        if [ "$?" = "0" ];then
            echo "$i is mounted, now umount it"
            echo "fuser -mk /media/${i#*/dev/}"
            fuser -mk /media/${i#*/dev/}
            umount -lf $i
        else
            echo "$i is not mounted, do nothing"
        fi

    done
}

function umount_disk_all_partition()
{
    for i in `ls /dev/$1*`
    do
        mount |grep "$i "
        if [ "$?" = "0" ];then
            echo "$i is mounted, now umount it"
            echo "fuser -mk /media/${i#*/dev/}"
            fuser -mk /media/${i#*/dev/}
            umount -lf $i
        else
            echo "$i is not mounted, do nothing"
        fi

    done
}

function handle_one_disk()
{
        dev_path=/dev/$1

        create_partition_ $dev_path
        if [ "$?" = "1" ];then
            echo "create_partition for disk $dev_path failed!"
            continue
        fi

        format_partition_ $dev_path
        if [ "$?" = "1" ];then
            echo "format_partition for disk $dev_path failed!"
        fi
}

function handle_all_disk()
{
    for i in `ls /dev/sd*`
    do
        dev_len=${#i}
        dev_path=$i

        if [ $dev_len -eq 8 ];then
            echo "$dev_path is a disk, handle it now"

            create_partition_ $dev_path
            if [ "$?" = "1" ];then
                echo "create_partition for disk $dev_path failed!"
                continue
            fi

            format_partition_ $dev_path
            if [ "$?" = "1" ];then
                echo "format_partition for disk $dev_path failed!"
            fi

        else
            echo "$dev_path is a partition, do nothing"
        fi
    done
}

function mount_all_partition()
{
    if [ -f "/thunder/bin/replugin_usb" ];then
        /thunder/bin/replugin_usb
    else
        reboot
    fi
}

check_running_instance

if [ -n "$1" ]; then
    ask_for_confirmation $1
    echo "disk: $1 is going to be handled!"
    umount_disk_all_partition $1
    handle_one_disk $1
else
    ask_for_confirmation
    echo "all disk are going to be handled!"
    umount_all_partition
    handle_all_disk
fi

mount_all_partition
