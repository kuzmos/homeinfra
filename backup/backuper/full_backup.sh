#!/bin/ksh
if [[ $# -ne 2 ]]; then
	echo "Expected 2 parameters: <name_of_collection> <backup_date>"
	exit 1
fi

legal_fn=`echo "${1}" | sed 's/\//#/g'`
fns="${legal_fn}-"${2}".gz_*"
backup_type="FULL"

folder_names_include="/home/admin/backup_scripts/private/full_folders_include.sh"
. "${folder_names_include}"

remote_server_include="/home/admin/backup_scripts/private/remote_server_include.sh"
. "${remote_server_include}"

backup_date="${2}"
collection_name="${1}"

backup_cadaver_functions="/home/admin/backup_scripts/backup_cadaver_functions.sh"
. "${backup_cadaver_functions}"

backup_scp_functions="/home/admin/backup_scripts/backup_scp_functions.sh"
. "${backup_scp_functions}"

backup_general_template="/home/admin/backup_scripts/backup_general_template.sh"
. "${backup_general_template}"
