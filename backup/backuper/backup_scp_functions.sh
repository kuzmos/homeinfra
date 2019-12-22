scp_backup() {

	if [[ $# -ne 4 ]]; then
		echo "Incorrect number of parameters for function scp_backup"
		echo "Expected: 4, got: $#"
		echo "Terminating script"
		exit 1
	fi

	typeset fn_mask="${1}"
	typeset webdav_dir="${2}"
	typeset nas_dir="${3}"
	typeset remote_command="${4}"

	typeset all_files=`${remote_command} "ls \"${nas_dir}\"/${fn_mask} 2>/dev/null || echo ''"`

	if [[ -z ${all_files} ]]; then
		typeset all_files_count=0
	else
		typeset all_files_count=`echo "${all_files}" | wc -l | sed -e 's/^ *//'`
	fi

	typeset failed_files_count=0

	typeset scp_output_fn=`mktemp /tmp/scp.out.XXXXXX`
	echo "Outputting progress to ${scp_output_fn}"
	for fn in `echo "${all_files}"` 
	do
		echo "Copying ${fn} to ${webdav_dir}..."
		$(${remote_command} "cp -f ${fn} ${webdav_dir}" 2>>${scp_output_fn})
		if [[ $? -ne 0 ]]; then
			echo "${fn} : failed to copy to ${webdav_dir} using command ${remote_command} \"cp -f ${fn} ${webdav_dir}\"" >> "${scp_output_fn}" 2>&1 
			let failed_files_count=${failed_files_count}+1
		fi
	done

	typeset all_copied_files=`${remote_command} "ls \"${webdav_dir}\"/${fn_mask} 2>/dev/null || echo ''"`

	if [[ -z ${all_copied_files} ]]; then
		typeset all_copied_files_count=0
	else
		typeset all_copied_files_count=`echo "${all_copied_files}" | wc -l | sed -e 's/^ *//'`
	fi

	if [[ "${failed_files_count}" -ne 0 || "${all_files_count}" -eq 0 ]]; then

		if [[ "${all_files_count}" -eq 0 ]]; then
			echo "No valid files to be uploaded"
		else
			echo "${failed_files_count} files out of ${all_files_count} failed to be uploaded"
			echo "Check the output at ${scp_output_fn}"
		fi
		return 1
	else
		if [[ "${all_copied_files_count}" -eq "${all_files_count}" ]]; then
			echo "All ${all_files_count} file(s) uploaded successfully"
			return 0
		fi
		
		echo "Source and destination number of files differ"
		echo "Source files count: ${all_files_count}, destination files count: ${all_copied_files_count}"
		return 1
	fi
}
