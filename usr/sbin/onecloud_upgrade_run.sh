#!/bin/sh

# Not work in factory mode
SOFTMODE=`fw_printenv xl_softmode |  awk -F "=" '{print $2}'`
[ "$SOFTMODE" == "factory" ] && exit 0

# make dir
mkdir -p /var/cache/opkg-upgrade

# Set stack size(KB).
ulimit -s 2048

APP_MODULES="upgrade"

upgradelog=/tmp/upgrade.log

UPGRADE_ROOT_DIR="/onecloud_upgrade"
UPGRADE_MASTER_FILE="${UPGRADE_ROOT_DIR}/upgrade_master"
UPGRADE_PREFIX_DIR=

log()
{
    echo -e "`date '+%Y-%m-%d %T'` $$-0x00000000  $1  -- <WARN> onecloud_upgrade_run.sh" >> ${upgradelog}
}

sn=`cat /tmp/miner_sn`

report()
{
    curl -s -H 'Content-Type: application/json; charset=utf-8' -X POST -m 30 --data \
    '[{"type":105,"sn":"'$sn'","uv":"","action_time":0,"status":"checksum fail","errcode":0,"message":"'$1'"}]' \
    'http://xyajs.data.p2cdn.com/o_onecloud_xyipk' &
}

check_md5_file()
{
    log "check dir ${1}, line $2"
    local check_dir=$1
    local md5must=`echo $2 | awk '{ print $1 }'`
    local filename=`echo $2 | awk '{ print $2 }'`

    local md5real=`md5sum "${check_dir}/${filename}" | awk '{ print $1 }'`
    if [ "${md5must}" != "${md5real}" ]; then
        log "file md5 not match, filename ${filename}, must ${md5must}, real ${md5real}"
        report "${check_dir}/${filename}"
        return 1
    fi

    return 0
}

check_md5_list()
{
    local md5_file="${1}/usr/share/onecloud-upgrade/md5sum.list"
    log "upgrade md5sum list file is ${md5_file}"
    if [ ! -f "${md5_file}" ]; then
        log "md5_list_file not exist ${md5_file}"
        return 2
    fi

    while read line
    do
        log "check ${1} line $line"
        check_md5_file "$1" "${line}"
        if [ $? -ne 0 ]; then
            # ipk may damaged
            return 1
        fi
    done < ${md5_file}

    return 0
}

get_prefix_dir()
{
    local ipk=
    log "upgrade master file ${UPGRADE_MASTER_FILE}"
    # check upgrade master exist or not
    if [ -f "${UPGRADE_MASTER_FILE}" ]; then
        master=`cat ${UPGRADE_MASTER_FILE}`
        log "content of upgrade master is ${master}"
        if [ "${master}" == "ipk0" ]; then
            ipk="ipk0"
        elif [ "${master}" == "ipk1" ]; then
            ipk="ipk1"
        else
            # use default
            log "content of upgrade master is invalid"
            return 0
        fi
    else
        log "upgrade master ${UPGRADE_MASTER_FILE} is not exist"
        return 0
    fi

    check_md5_list "${UPGRADE_ROOT_DIR}/${ipk}"

    if [ $? -ne 0 ]; then
        # use default
        log "check md5 list fail"
        return 0
    fi
    
    UPGRADE_PREFIX_DIR="${UPGRADE_ROOT_DIR}/${ipk}"
    log "upgrade path prefix is ${UPGRADE_PREFIX_DIR}"
}

run_upgrade()
{
    log "upgrade running, prefix path '${UPGRADE_PREFIX_DIR}'"

    unset LD_LIBRARY_PATH
    if [ "${UPGRADE_PREFIX_DIR}" != "" ]; then
        ${UPGRADE_PREFIX_DIR}/usr/sbin/upgrade -p "${UPGRADE_PREFIX_DIR}" > /dev/null 2>&1 &
    else
        /usr/sbin/upgrade > /dev/null 2>&1 &
    fi
}

monitor_modules()
{
    ubus call upgrade get_status -t 30 >/dev/null 2>&1
    if [[ $? -eq 7 || $? -eq 4 ]]; then          #Request timed out(7) OR Object not found(4)
        (killall upgrade; sleep 2; killall -9 upgrade) >/dev/null 2>&1
        run_upgrade
    fi
}

get_prefix_dir

run_upgrade

while :
do
    sleep 10
    monitor_modules
done

