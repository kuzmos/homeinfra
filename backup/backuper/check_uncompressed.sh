#!/bin/ksh
if [[ $# -ne 3 ]]; then
	echo "Expected 3 parameters: <location_of_uncompressed_backups> <monitoring_email_address> <dir_scripts_prefix>"
	exit 1
fi

typeset location="${1}"
typeset monitoring_email="${2}"
typeset dir_scripts_prefix="${3}"

mail_include="${dir_scripts_prefix}/mail_include.sh"
. "${mail_include}"

message="$(date): Checking contents of ${location}\n"
number_of_files=`ls ${location} | wc -l`
size_of_files=`du -hc ${location} | tail -n 1 | cut -f1`

if [[ ${number_of_files} -gt 0 ]]; then
	message="========\nWARNING\n========\n"
	subject_line="WARN: ${number_of_files} files of uncompressed backups"
else
	subject_line="OK: No uncompressed backups"
fi

message="${message}Number of files in ${location}: ${number_of_files} file(s), total size ${size_of_files}\n"
echo ${message}
start_date=`gdate '+%s'`
mail_content="\
Subject:$(hostname): ${subject_line}\n\
${email_header}\n\
${message}\n\
${email_footer}\n"

# echo "Mail content:"
# echo ${mail_content}
echo "${mail_content}" | sendmail $monitoring_email
