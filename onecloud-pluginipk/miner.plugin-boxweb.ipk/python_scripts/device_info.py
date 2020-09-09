import os
import json
import time

ret = {"error_code":0}

def get_activation_code():
    for i in range(1, 30):
        ret["need_activation"] = True
        ret_json_str = os.popen("ubus call activate_auth device_getstatus").read()
        if ret_json_str != "":
            dict = json.loads(ret_json_str)
            if dict["process_status"] == 0:
                ret["ret"] = dict["ret"]
                ret["status"] = dict["status"]
                ret["activation_code"] = dict["activation_code"]
                    
                if ret["ret"] != 0:  #getinfo failed
                    ret["activation_code"] = ""
                    ret["status"] = 0
                    ret["error_code"] = ret["ret"]
                    return 1
                
                if ret["status"] != 1:  #not activated
                    ret["activation_code"] = ""
                    ret["error_code"] = 0
                    return 0
                else:                   #activated
                    if ret["activation_code"] == "":
                        ret["activation_code"] = "activation code lost"
                    ret["error_code"] = 0
                    ret["need_activation"] = False
                    return 0

        time.sleep(1)

    ret["activation_code"] = ""
    ret["status"] = ""
    ret["error_code"] = 1
    return 1


get_activation_code()


json_str3 = os.popen("ubus call netcfg get_network").read()

if json_str3 != "":
    dict3 = json.loads(json_str3)
    ret["type"] = dict3["type"]
    ret["ip"] = dict3["ip"]
    ret["netmask"] = dict3["netmask"]
    ret["gateway"] = dict3["gateway"]
    ret["dnstype"] = dict3["dnstype"]
    ret["dns1"] = dict3["dns1"]
    ret["dns2"] = dict3["dns2"]
else:
    ret["type"] = ""
    ret["ip"] = ""
    ret["netmask"] = ""
    ret["gateway"] = ""
    ret["dnstype"] = ""
    ret["dns1"] = ""
    ret["dns2"] = ""

if os.path.isfile("/.sys_ver"):
    file = open("/.sys_ver")
    i = file.readline()
    i = i.rstrip()
    ret["sys_version"] = i
    ret["app_version"] = i
else:
    ret["sys_version"] = ""
    ret["app_version"] = ""

if os.path.isfile("/tmp/.efuse_sn"):
    file = open("/tmp/.efuse_sn")
    i = file.readline()
    i = i.rstrip()
    ret["sn"] = i
else:
    ret["sn"] = ""

if os.path.isfile("/sys/class/net/eth0/address"):
    file = open("/sys/class/net/eth0/address")
    i = file.readline()
    i = i.rstrip()
    ret["mac"] = i
else:
    ret["mac"] = ""

json_str_ret = json.dumps(ret)
print json_str_ret
