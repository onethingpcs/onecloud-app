import os
import resource
try:
	pid = os.fork()
	if pid == 0:
		#resource.setrlimit(resource.RLIMIT_VMEM, RLIM_INFINITY)
		resource.setrlimit(
    		resource.RLIMIT_AS,
    		(resource.RLIM_INFINITY, resource.RLIM_INFINITY))
		os.execl("/app/system/miner.plugin-csbox.ipk/bin/csbox", "")
	else:
		pass
except OSError, e:
	print "for return:", e
