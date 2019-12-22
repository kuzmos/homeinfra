#!/bin/ksh
#####################################################################################
# need to define backup_type, backup_date and collection_name in the executing script
#####################################################################################

failure() {
	typeset mail_content="\
Subject:$(hostname): Failed ${backup_type} backup by ${backup_method} of ${collection_name} for date ${backup_date}\n\
${email_header}\n\
Error: ${1} \n\
${email_footer}"

	# send message that the backup has finished
	echo "${mail_content}" | sendmail $monitoring_email
}

# input parameters check
if [[ -z $monitoring_email ]]; then
	echo "Monitoring email address is empty."
	exit 1
fi

if [[ -z $remote_command ]]; then
	failure "Secure copy server parameter is empty."
	exit 1
fi

# select method of backup
# if backup linux VM is available, prefer SCP
# otherwise, use cadaver to upload directly to webdav

# remote command defined in external file
${remote_command} 'echo hello'>/dev/null 2>&1
if [[ $? -ne 0 ]]; then
	typeset backup_method="cadaver"
else
	typeset backup_method="scp"
fi

typeset message="$(date): Starting back up of ${fns}\n"
typeset number_files_to_backup=`ls ${path_prefix}/${fns} | wc -l | sed -e 's/^ *//'`

typeset size_files_to_backup=`du -hc ${path_prefix}/${fns} | tail -n 1 | cut -f1`
message="${message}Backing up ${number_files_to_backup} file(s), total size ${size_files_to_backup}\n"
message="${message}Backup method: ${backup_method}\n"
echo ${message}
typeset start_date=`gdate '+%s'`
typeset mail_content="\
Subject:$(hostname): Started ${backup_type} backup by ${backup_method} of ${collection_name} for date ${backup_date}\n\
${email_header}\n\
${message}\n\
${email_footer}\n"

# send email that the backup has started
echo "${mail_content}" | sendmail $monitoring_email

if [[ "${number_files_to_backup}" -eq 0 ]]; then
	failure "No files to backup. The pattern ${fns} did not match any file."
	exit 1
fi

# run actual backup
if [[ "${backup_method}" = "cadaver" ]]; then
	typeset cadaver_config=$(get_cadaver_config "${fns}" "${backup_remote_folder}" "${path_prefix}")
	typeset stdoutput=$(cadaver_backup "${cadaver_config}")

	# failure occured, need to email
	if [[ $? -ne 0 ]]; then
		failure "Cadaver backup failed with stdout:\n ${stdoutput}"
		exit 1
	fi

elif [[ "${backup_method}" = "scp" ]]; then
	typeset stdoutput=$(scp_backup "${fns}" "${scp_backup_remote_folder}" "${scp_nas_path_prefix}" "${remote_command}" )
	# failure occured, need to email
	if [[ $? -ne 0 ]]; then
		failure "scp backup failed with stdout:\n ${stdoutput}"
		exit 1
	fi
else
	failure "${backup_method} is unknown"
	echo "Sending mail and terminating script"
	exit 1
fi

message="$(date): Finished back up of ${fns}\n"
message="${message}Backup standard output:\n\n"
message="${message}${stdoutput}"
typeset finish_date=`gdate '+%s'`
let total_runtime_sec=${finish_date}-${start_date}
typeset total_runtime=`gdate -u -d @${total_runtime_sec} +"%T"`

mail_content="\
Subject:$(hostname): Finished ${backup_type} backup by ${backup_method} of ${collection_name} for date ${backup_date}\n\
${email_header}\n\
Total runtime: ${total_runtime}\n\
${message}\n\
${email_footer}"

# send message that the backup has finished
echo "${mail_content}" | sendmail $monitoring_email
