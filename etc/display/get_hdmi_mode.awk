#!/usr/bin/awk
BEGIN{
    output_mode = "720p60hz"
}
/\*/{
    output_mode = $0
    sub(/\*/, "", output_mode)
}
END{
    print output_mode
}
