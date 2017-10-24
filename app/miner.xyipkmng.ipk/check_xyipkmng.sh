#!/bin/sh

base_path=$(dirname $0)
MAIN_EXE='xyipkd'
while true :
do
    sleep 10
    for EXE in ${MAIN_EXE}
    do
        pid=`ps | grep ${EXE} | grep -v grep | awk '{print $1}'`
        if  [ "$pid" ]; then
            sleep 20
        else
            sh ${base_path}/start.sh &
            exit 1 
        fi
    done
done 


