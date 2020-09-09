#!/bin/sh

printf "Content-Disposition: attachment; filename=diag_log\r\n"
printf "\r\n"
#printf "diag.cgi!\n"

sh /onecloud-pluginipk/miner.plugin-boxweb.ipk/python_scripts/diag.sh
cat /tmp/diag_log.enc
