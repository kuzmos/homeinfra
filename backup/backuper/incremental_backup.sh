#!/bin/ksh
if [[ $# -ne 11 ]]; then
	echo "Expected 11 parameters: <name_of_collection> <first_backup_date> <second_backup_date> <remote_scp_command> <monitoring_email_address> <backup_remote_server_dir> <scp_backup_remote_folder> <scp_nas_path_prefix> <source_path_prefix> <backup_webdav_server> <dir_scripts_prefix>"
	exit 1
fi

legal_fn=`echo "${1}" | sed 's/\//#/g'`
fns="${legal_fn}-"${2}"-"${3}".gz_*"
backup_type="INCREMENTAL"

typeset remote_command="${4}"
typeset monitoring_email="${5}"
typeset backup_remote_folder="${6}"
typeset scp_backup_remote_folder="${7}"
typeset scp_nas_path_prefix="${8}"
typeset path_prefix="${9}"
typeset backup_server="${10}"
typeset dir_scripts_prefix="${11}"

# include email settings
typeset mail_include="${dir_scripts_prefix}/mail_include.sh"
. ${mail_include}

backup_date="${2} - ${3}"
collection_name="${1}"

backup_cadaver_functions="${dir_scripts_prefix}/backup_cadaver_functions.sh"
. "${backup_cadaver_functions}"

backup_scp_functions="${dir_scripts_prefix}/backup_scp_functions.sh"
. "${backup_scp_functions}"

backup_general_template="${dir_scripts_prefix}/backup_general_template.sh"
. "${backup_general_template}"
