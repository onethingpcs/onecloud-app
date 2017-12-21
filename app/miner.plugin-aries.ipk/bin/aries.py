import os
import sys
import json
import httplib
import time
import hashlib
from daemon import Daemon

from os.path import dirname, abspath
base_path = dirname(abspath(__file__))
sys.path.append(base_path)


def _get_ipk_process_status_filter():
    filter = {}
    filter['plugin-minion']    = 'python minion/src/minion/minion.py start'
    filter['plugin-iqiyihapp'] = './happ /tmp/dcdn_base/.thirdapp/pluginiqiyihapp_DATA'
    return filter

def _handle_error(msg):
    sys.stderr.write(msg + "\n")
    _log(msg)

def _log(msg):
    fp = open("/tmp/aries.log", 'a+')
    fp.write(msg + "\n")
    fp.close()

def _data_report(data):
    ts    = int(time.time()) + 60 * 60 * 24;
    user  = "node"
    key   = "d6asdadadab52144f29da0efcf3s91454"
    text  = "Openzqb.IpkInstallStatusReport" + user + key + str(ts)
    md5   = hashlib.md5()
    md5.update(text)
    token = md5.hexdigest()
    sign  = user + "-" + str(ts) + "-" + token
    conn = httplib.HTTPConnection("mc-service.live.p2cdn.com", 80, False, 5)
    conn.request('POST', '/index.php?Action=Openzqb.IpkInstallStatusReport&Sign=' + sign, json.dumps(data))
    res = conn.getresponse()
    if int(res.status) != 200:
        _handle_error("report data failed: status = " + str(res.status))
        conn.close()
        return False

    body = res.read()
    conn.close()
    try:
        result = json.loads(body)
    except Exception as e:
        _handle_error("report data failed2: body = " + str(body))
        return False

    if (type(result) == type({})) and (result.has_key('code')) and (result['code'] == 0):
        return True
    else:
        return False

def _get_sn():
    try:
        fp = open("/tmp/miner_sn", 'r+')
        content = fp.readline()
        fp.close()
    except Exception as e:
        _handle_error("get sn failed: {0}" . format(str(e)))
        return False

    sn = content.strip()
    return sn

def get_ipk_versions():
    pipe = os.popen("ubus call xyipk list 2>/dev/null")
    output = pipe.read()
    pipe.close()

    try:
        result = json.loads(output)
    except Exception as e:
        _handle_error("ubus return failed, reason: {0}" . format(str(e)))
        return False

    if (type(result) != type({})) or (False == result.has_key("ipk_list")):
        _handle_error("ubus return invalid, result: {0}" . format(str(result)))
        return False

    ipk_list_info = result['ipk_list']

    ipk_versions = []

    for item in ipk_list_info:
        if "uninstalled" == item['status']:
            continue

        one = {}
        one['package'] = item['package']
        one['version'] = item['version']
        one['latest_version'] = item['latest_version']
        one['installed_time'] = item['installed_time']
        ipk_versions.append(one)

    return ipk_versions

def get_ipk_process_status(package, process_filter):
    process_status = -100 #process status get failed
    ps_process_cmd = "ps | grep '" +  process_filter + "' |grep -v grep|awk '{print $1}'"
    pipe = os.popen(ps_process_cmd)
    output = pipe.read()
    pipe.close()

    process_id = int(output)
    #process not running
    if process_id <= 0:
        process_status = -1
        return process_status

    process_status = 1 #process running

    ls_process_cmd = "ls -l /proc/" + str(process_id) + "/exe | grep delete | grep -v grep"
    pipe = os.popen(ls_process_cmd)
    output = pipe.read()
    pipe.close()

    output = output.strip()
    if 0 != len(output):
        process_status = 2 #process running but bin file deleted

    return process_status

class TaskWorker(Daemon):

    def __init__(self, pidfile):
        super(TaskWorker, self).__init__(pidfile)
        self.sleep_seconds = 180
        self.loop_times = 1


    def run(self):
        sn = _get_sn()
        while True:
            _log("running... loops:" + str(self.loop_times))
            self.loop_times += 1
            #do loop task
            _run(sn)

            #if self.loop_times <= 0:
            #    _log("loop over...")
            #    break

            time.sleep(self.sleep_seconds)

def _run(sn):
    ipk_versions = get_ipk_versions()
    if False == ipk_versions:
        _handle_error("get_ipk_versions failed")
        return False

    ipk_process_status_filter = _get_ipk_process_status_filter()
    ipk_status_list = []
    for item in ipk_versions:
        package = item['package']
        if False == ipk_process_status_filter.has_key(package):
            item['process_status'] = 0
        else:
            item['process_status'] = get_ipk_process_status(package, ipk_process_status_filter[package])

        ipk_status_list.append(item)

    report_data = {}
    report_data['sn']   = sn
    report_data['list'] = ipk_status_list

    for i in range (1, 4):
        if True == _data_report(report_data):
            break;
        else:
            if i == 3:
                break

            _handle_error("data report failed, retry times " + str(i))
            time.sleep(3 * i)

def main():
    if len(sys.argv) < 2:
        sys.stderr.write("Usage: aries.py start|stop|restart\n")
        sys.exit(1)

    action = sys.argv[1]

    pidfile = '/var/run/aries.pid'
    worker = TaskWorker(pidfile)

    if action == "start":
        worker.start()
    elif action == "stop":
        worker.stop()
    elif action == "restart":
        worker.restart()
    else:
        sys.stderr.write("Don't support option %s\n" % action)
        sys.stderr.write("Usage: Usage start|stop|restart\n")
        sys.exit(1)

if __name__ == "__main__":
    main()