#!/bin/ksh

# login_failures.sh
#
# Usage: login_failures.sh [-i] [-n] /path/to/maillog
#
#   -i    Output unique client IP addresses (default prints full sessions)
#   -n    Convert IPs to /24 network format (implies -i)
#   logfile  Path to your maillog
#
# Outputs either full SMTP session logs or unique client IPs (or /24 networks)
# for sessions that saw a connection followed by an authentication failure.
#
# Dependencies: awk, sort, uniq (standard OpenBSD toolchain)

# Parse options
ip_only=0
netmask=0
while getopts ":in" opt; do
  case "$opt" in
    i) ip_only=1 ;;
    n) netmask=1; ip_only=1 ;;  # -n implies -i
    *) print "Usage: $0 [-i] [-n] /path/to/maillog"; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

# Check logfile argument
if [ $# -ne 1 ]; then
  print "Usage: $0 [-i] [-n] /path/to/maillog"
  exit 1
fi

LOGFILE=$1
if [ ! -r "$LOGFILE" ]; then
  print "Error: Cannot read log file '$LOGFILE'"
  exit 1
fi

awk -v ip_only="$ip_only" -v netmask="$netmask" '
  # Capture “connected” lines, extract session ID and IP
  /smtp connected address=/ {
    sid = $6
    # split on "address=" then space to get IP
    split($0, parts, "address=")
    split(parts[2], addr, " ")
    ip_by_sid[sid] = addr[1]
    sessions[sid] = sessions[sid] $0 ORS
    has_connect[sid] = 1
    next
  }
  # Capture authentication failures
  /smtp authentication user=.*result=permfail/ ||
  /smtp failed-command/ {
    sid = $6
    sessions[sid] = sessions[sid] $0 ORS
    has_fail[sid] = 1
    next
  }
  # For context, accumulate any other lines in recorded sessions
  {
    sid = $6
    if (sid in sessions) {
      sessions[sid] = sessions[sid] $0 ORS
    }
  }
  END {
    for (sid in sessions) {
      if (has_connect[sid] && has_fail[sid]) {
        if (ip_only) {
          ip = ip_by_sid[sid]
          if (netmask) {
            split(ip, o, ".")
            ip = o[1] "." o[2] "." o[3] ".0/24"
          }
          print ip
        } else {
          printf "%s\n", sessions[sid]
        }
      }
    }
  }
' "$LOGFILE" | sort -u

