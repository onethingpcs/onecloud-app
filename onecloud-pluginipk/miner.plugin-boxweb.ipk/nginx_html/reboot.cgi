#!/bin/sh

printf "Content-Type: text/plain; charset=utf-8\r\n"
printf "\r\n"
#printf "reboot.cgi!\n"
printf '{"error_code": 0}'
#ubus call mnt reboot
python /onecloud-pluginipk/miner.plugin-boxweb.ipk/python_scripts/reboot.py
