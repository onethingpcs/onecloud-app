#!/bin/sh

# App to kill list.Must the same with /thunder/etc/start_app.sh.
#APP_MODULES="quota netcfg mnt upgrade remote hsd devicemgr thunder/bin/stat thunder/bin/dcdn iopsmgr"
APP_MODULES="quota netcfg mnt upgrade hsd thunder/bin/stat iopsmgr thunder/bin/dcdn config_watcher"


kill_monitor ()
{
  mon_pid=`ps | grep -e start_app.sh -e start_otc_base.sh | grep -v grep | awk '{print $1}'`
  if [ -n "$mon_pid" ]; then
    kill -9 $mon_pid
    echo "[$0] kill monitor $mon_pid"
  fi
}

kill_app ()
{
  for name in $APP_MODULES
  do
    app_pid=`ps | grep $name | grep -v grep | awk '{print $1}'`
    if [ -n "$app_pid" ]; then
      kill -9 $app_pid
      echo "[$0]kill -9 $app_pid of $name"
    fi
  done
  
}

kill_monitor

for name in $APP_MODULES
do
	killall $name
  echo "[$0]killall $name"
done

kill_app

killall dcdn_client
killall opkg
killall wget
killall minissdpd

exit 0
