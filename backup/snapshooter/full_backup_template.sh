#!/bin/csh
if ($# != 4 && $# != 5) then
	echo "Expected 4 or 5 parameters: <vol_name> <dataset_name> <username> <backups_path> [snapshot_date]"
	exit 1
endif

set username="${3}"
set backups_path="${4}"

if ($# == 4) then
	echo "Backing up last snapshot for ${2}"
	set snapshot_date=`zfs list -r -t snapshot -o name -S creation -H ${1}/${2} | head -1 | cut -d "@" -f 2 | cut -d "-" -f 2 | cut -d "." -f 1`
else
	echo "Backing up snapshot for ${2} from ${5}"
	set snapshot_date="${5}"
endif

set snapshot_name=`zfs list -r -t snapshot -o name -S creation -H ${1}/${2} | head -1`
set legal_fn=`echo "${2}" | sed 's/\//#/g'`
set full_fn="${backups_path}/${legal_fn}-${snapshot_date}.bak"
echo "Backing up snapshot ${snapshot_name} to ${full_fn}"
zfs send ${snapshot_name} > ${full_fn}

if ($? == 0) then
	echo "Snapshot ${snapshot_name} stored successfully as ${full_fn}" 
	echo "Changing owner of ${full_fn} to ${username}:${username}"
	chown "${username}":"${username}" "$full_fn"
	echo "File size: `du -h '${full_fn}' | cut -f 1`"
	exit 0
else
	echo "Failed to store snapshot ${snapshot_name} as ${full_fn}"
	exit 1
endif
