#!/bin/sh

printf "Content-Type: text/plain; charset=utf-8\r\n"
printf "\r\n"
#printf "reset.cgi!\n"
printf '{"error_code": 0}'
#ubus call mnt reset
python /onecloud-pluginipk/miner.plugin-boxweb.ipk/python_scripts/reset.py
