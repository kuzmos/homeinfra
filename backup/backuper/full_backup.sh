#!/bin/ksh
if [[ $# -ne 10 ]]; then
	echo "Expected 10 parameters: <name_of_collection> <backup_date> <remote_scp_command> <monitoring_email_address> <backup_remote_server_dir> <scp_backup_remote_folder> <scp_nas_path_prefix> <source_path_prefix> <backup_webdav_server> <dir_scripts_prefix>"
	exit 1
fi

legal_fn=`echo "${1}" | sed 's/\//#/g'`
fns="${legal_fn}-"${2}".gz_*"
backup_type="FULL"

typeset remote_command="${3}"
typeset monitoring_email="${4}"
typeset backup_remote_folder="${5}"
typeset scp_backup_remote_folder="${6}"
typeset scp_nas_path_prefix="${7}"
typeset path_prefix="${8}"
typeset backup_server="${9}"
typeset dir_scripts_prefix="${10}"

backup_date="${2}"
collection_name="${1}"

backup_cadaver_functions="${dir_scripts_prefix}/backup_cadaver_functions.sh"
. "${backup_cadaver_functions}"

backup_scp_functions="${dir_scripts_prefix}/backup_scp_functions.sh"
. "${backup_scp_functions}"

backup_general_template="${dir_scripts_prefix}/backup_general_template.sh"
. "${backup_general_template}"
