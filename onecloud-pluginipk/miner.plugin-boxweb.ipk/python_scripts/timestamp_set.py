import sys
import json
import os
import time
import commands
import subprocess
import re

checktime=1564592461

def run_cmd(cmd):
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    out = p.stdout.readlines()
    ret_value = ""
    for line in out:
        ret_value += line
    return ret_value

ret = {"ret":0}

def timestamp_setting():
    json_str = sys.stdin.readline()

    if json_str == "":
        return '{"error_code":1}'
    
    dict = json.loads(json_str)
    if not(dict.has_key("timestamp")):
        return '{"error_code":1}'
		
    cur_time=int(time.time());
    if cur_time >= checktime:
        #print "time is ok"
        ret["ret"] = 0
        return 0
	
    if not(re.match("[0-9.]*$", dict["timestamp"])):
        return '{"error_code":2}'

    localtime = time.strftime("%Y-%m-%d %H:%M:%S",  time.localtime(float(dict["timestamp"])))

    process_cmd = "date -s " + "\"" + str(localtime) + "\""
    #print "process_cmd = ", process_cmd
    run_cmd(process_cmd)
	
    ret["ret"] = 0
    return 0


timestamp_setting()

json_str_ret = json.dumps(ret)
print json_str_ret
