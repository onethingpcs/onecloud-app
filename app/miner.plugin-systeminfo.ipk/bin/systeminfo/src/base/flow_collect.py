import os
import re
import logging

logger = logging.getLogger(__name__)

INFPATTERN = re.compile("eth0:(.*)$", re.MULTILINE)
MACFLOW = "/proc/net/dev"
PREVFLOW = "/var/run/.flowdiff"

def get_machine_flow():
    flow = None
    try:
        with open(MACFLOW) as fd:
            content = fd.read()
            m = INFPATTERN.search(content)
            if m and len(m.groups()) == 1:
                flow = m.group(1).split()[8]
    except Exception as e:
        logger.error("get machine flow failed, reason: {0}".format(str(e)))
    if flow:
        flow = int(flow)
    return flow
                
def flow_diff():
    cur_flow = get_machine_flow()
    prev_flow = 0
    res = 0
    if not os.path.exists(PREVFLOW):
        with open(PREVFLOW, "w") as fd:
            fd.write(str(cur_flow))
        return 0
    else:
        with open(PREVFLOW, "rw+") as fd:
            content = fd.readline().strip()
            if content:
                prev_flow = int(content)
            fd.seek(0)
            fd.write(str(cur_flow))
            fd.truncate()
        if cur_flow:
            if cur_flow < prev_flow:
                return cur_flow   
            res = cur_flow - prev_flow
        return res
        

              
                
      

        