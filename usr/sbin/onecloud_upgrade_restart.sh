#!/bin/sh

log()
{
    echo -e "`date '+%Y-%m-%d %T'` $$-0x00000000  $1  -- <WARN> onecloud_upgrade_restart.sh" >> /tmp/upgrade.log
}

log "onecloud_upgrade_restart.sh running"

# kill now running instance
while :
do
    pid=`ps | grep 'onecloud_upgrade_run.sh' | grep -v 'grep' | awk -F ' ' '{print $1}'`

    if [ -n "$pid" ]; then
        log "kill [$pid] onecloud_upgrade_run.sh"
        kill -9 $pid
        sleep 1
    else
        break
    fi
done

sleep 1

while :
do
    echo "`ps | grep 'upgrade' | grep -v 'grep' `"
    pid=`ps | grep 'upgrade' | grep -v 'grep' | grep -v 'onecloud_upgrade_restart.sh' | awk -F ' ' '{print $1}'`
    if [ -n "$pid" ]; then
        log "kill [$pid] upgrade"
        kill -9 $pid
        sleep 1
    else
        break
    fi
done

sleep 1

# begin a new era
sh /usr/sbin/onecloud_upgrade_run.sh &

exit 0
