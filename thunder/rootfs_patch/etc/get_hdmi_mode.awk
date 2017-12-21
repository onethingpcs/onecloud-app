#!/usr/bin/awk

BEGIN {
	IGNORECASE = 1

	# we supported resolutions
	a_n = 0
    a[a_n++] = "720p"
	a[a_n++] = "1080p"
	
	b_n = 0
}

{
	# the tv supported resolutions
	b[b_n++] = $0
}

END {
	# get the tv best resolution
	b_best = -1
	for (i = 0; i < b_n; i++) {
		if (match(b[i], "*") > 0) {
			#print "tv best resolution is " b[i], "index is " i
			b_best = i;
			break
		}
	}

	if (b_best != -1) {
		# got the tv best resolution, check whether we support it or not?
		for (i = 0; i < a_n; i++) {
			if (match(b[b_best], a[i]) > 0) {
				# yes, we support it
				print a[i]
				exit 0
			}
		}
	}

	# did not get the tv best resolution or we not supported it
	# try to use the best match resolution that each support

	for (i = a_n - 1; i >= 0; i--) {
		for (j = 0; j < b_n; j++) {
			if (match(b[j], a[i]) > 0) {
				# got the best match resolution
				print a[i]
				exit 0
			}
		}
	}

	# the default
	print a[0]
	exit 1
}
