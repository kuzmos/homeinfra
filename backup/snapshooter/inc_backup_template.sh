#!/bin/csh
if ($# != 4) then
	echo "Expected 4 parameters: <vol_name> <dataset_name> <username> <backups_path>"
	exit 1
endif

set username="${3}"
set backups_path="${4}"

set last_snapshot_date=`zfs list -r -d 1 -t snapshot -o name -S creation -H "${1}/${2}" | head -1 | cut -d "@" -f 2 | cut -d "-" -f 2 | cut -d "." -f 1`
set last_snapshot_name=`zfs list -r -d 1 -t snapshot -o name -S creation -H "${1}/${2}" | head -1`
set last_but_one_snapshot_date=`zfs list -r -d 1 -t snapshot -o name -S creation -H "${1}/${2}" | head -2 | tail -n 1 | cut -d "@" -f 2 | cut -d "-" -f 2 | cut -d "." -f 1`
set last_but_one_snapshot_name=`zfs list -r -d 1 -t snapshot -o name -S creation -H "${1}/${2}" | head -2 | tail -n 1`
set legal_fn=`echo "${2}" | sed 's/\//#/g'`
set legal_fn=`echo "${2}" | sed 's/\//#/g'`
set full_fn="${backups_path}/${legal_fn}-${last_but_one_snapshot_date}-${last_snapshot_date}.bak"
echo "Backing up increment between snapshots $last_but_one_snapshot_name and $last_snapshot_name to $full_fn"
zfs send -i "$last_but_one_snapshot_name" "$last_snapshot_name" > "$full_fn"

if ($? == 0) then
	echo "Increment between snapshots ${last_but_one_snapshot_name} and ${last_snapshot_name} stored successfully as ${full_fn}" 
	echo "Changing owner of ${full_fn} to ${username}:${username}"
	chown "${username}":"${username}" "$full_fn" 
	echo "File size: `du -h '${full_fn}' | cut -f 1`"
	exit 0
else
	echo "Failed to store increment between snapshots ${last_but_one_snapshot_name} and ${last_snapshot_name} as ${full_fn}"
	exit 1
endif
