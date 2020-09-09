import sys
import json
import os
import time
import re

value = {"ret":0}

def activate():
    json_str = sys.stdin.readline()

    if json_str == "":
        return '{"error_code":100}'
    
    dict = json.loads(json_str)
    if not(dict.has_key("activation_code")):
        return '{"error_code":100}'
			
    # for i in range(1, 10):
        # ret_json_str = os.popen("ubus call activate_auth device_getstatus").read()
        # if ret_json_str != "":
            # dict = json.loads(ret_json_str)
            # if dict["process_status"] == 0:
                # value["ret"] = dict["ret"]
                # value["status"] = dict["status"]
				
                # if value["ret"] != 0:  #getinfo failed
                    # ret_str = '{' + '"error_code":' + str(value["ret"]) + '}'
                    # print "ret_str = ", ret_str
                    # return str(ret_str)
					
                # if value["status"] == 1:  #activated already
                    # return '{"error_code":12}'
                # else:
                    # break
			
        # time.sleep(1)
    
    if not(re.match("^[A-Za-z0-9]*$", dict["activation_code"])):
        return '{"error_code":2}'

    data = "ubus call activate_auth device_activate '{\"activation_code\":\"%s\"}'" % (dict["activation_code"])

    for i in range(1, 30):
        ret_json_str = os.popen(data).read()
        if ret_json_str == "":
            return '{"error_code":100}'

        dict = json.loads(ret_json_str)
        if dict["process_status"] == 0 :
            return '{"error_code": %s}' % (dict["ret"])
    
        time.sleep(1)

    return '{"error_code":100}'

ret = activate()
print ret