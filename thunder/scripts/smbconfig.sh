#/bin/sh

# auto generate samba configuration file, /etc/samba/smb.conf

MNT_ROOT="/media"

smb_conf="/etc/samba/smb.conf"
smb_conf_tmp="/tmp/.smb.conf.$$"

rm -f ${smb_conf}
rm -f ${smb_conf_tmp}

# add the global config to configuration file
add_global_to_conf()
{
cat << EOF >> ${smb_conf_tmp}
[global]
    workgroup = WORKGROUP
    server string = ONECLOUD
    unix charset = UTF8
    
    security = user
    guest ok = yes
    guest account = root
    use mmap = yes
    map to guest = Bad User

    domain master = no
    local master = yes
    os level = 233
    preferred master = yes
    lm announce = yes
    lm interval = 10

    socket options = TCP_NODELAY IPTOS_LOWDELAY
    use sendfile = yes

    writeable = yes
    browseable = yes

    syslog = 1
    
EOF
}


# add a partition to configration file
# arg1 partition name
# arg2 partition mount point
# e.g. 
# add_partition_to_conf sda1 /media/sda1
add_partition_to_conf()
{
cat << EOF >> ${smb_conf_tmp}
[$1]
    path = $2
    public = yes
    writable = yes
    printable = no
    create mask = 0644
    directory mask = 0750
    
EOF
}

add_global_to_conf

#mount | grep '^/dev/sd' | while read -r line
for line in `ls -1 /dev/sd[a-z][0-9]`
do
    device=`echo ${line} | awk '{ print $1 }'`
    name=`echo ${device} | awk -F\/ '{ print $3 }'`
    mnt="${MNT_ROOT}/${name}"
    
    if [ -n ${device} -a -n ${name} -a -n ${mnt} ]
    then
        #echo "add conf: partition '${device}' name '${name}' mount on '${mnt}'" >> /tmp/smbconfig.log
        add_partition_to_conf ${name} ${mnt}      
    fi
done

cp -f ${smb_conf_tmp} ${smb_conf}
rm -f ${smb_conf_tmp}
# restart the smb daemons
/etc/init.d/S91smb restart
