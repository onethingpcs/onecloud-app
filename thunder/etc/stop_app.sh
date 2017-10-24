#!/bin/sh

# App to kill list.Must the same with /thunder/etc/start_app.sh.
APP_MODULES="netcfg mnt upgrade xqos dcdn remote fmgr fdrawer xldp turnclient sysmgr"

kill_monitor ()
{
  mon_pid=`ps | grep start_app.sh | grep -v grep | awk '{print $1}'`
  if [ -n "$mon_pid" ]; then
    kill -9 $mon_pid
    echo "[$0]kill monitor $mon_pid"
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
killall nginx

exit 0
