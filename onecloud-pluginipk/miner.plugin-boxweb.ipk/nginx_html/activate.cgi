#!/bin/sh

printf "Content-Type: text/plain; charset=utf-8\r\n"
printf "\r\n"
#printf "activate.cgi!\n"
python /onecloud-pluginipk/miner.plugin-boxweb.ipk/python_scripts/activate.py
