#!/bin/ksh

#!/bin/ksh
if [[ $# -ne 2 ]]; then
	echo "Expected 2 parameters: <filename with hostnames> <adblock_trap_ip>"
	exit 1
fi

for i in `cat "${1}"`; do printf "\nlocal-zone: \"$i\" redirect\nlocal-data: \"$i A "${2}"\""; done
