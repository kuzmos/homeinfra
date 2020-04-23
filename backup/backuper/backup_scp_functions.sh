scp_backup() {
	typeset retry_delay_s=5
	typeset check_delay_s=3
	if [[ $# -ne 4 ]]; then
		echo "Incorrect number of parameters for function scp_backup"
		echo "Expected: 4, got: $#"
		echo "Terminating script"
		exit 1
	fi
	typeset retries=5
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
		typeset file_basename=${fn##*/}
		# if target file does not exist or is different, copy
		typeset local_file_checksum=`${remote_command} "sha256sum ${fn} | cut -d ' ' -f 1"`	
		typeset remote_file_checksum=`${remote_command} "sha256sum ${webdav_dir}/${file_basename} | cut -d ' ' -f 1"`	

		echo "Local checksum: ${local_file_checksum}, remote checksum: ${remote_file_checksum}" >> ${scp_output_fn} 2>&1

		if [[ "${local_file_checksum}" != "${remote_file_checksum}" ]]; then

			echo "Remote file is not the same as local or is missing, copying ${fn} to ${webdav_dir}..."  >> "${scp_output_fn}" 2>&1

			$(${remote_command} "cp -f ${fn} ${webdav_dir}" >> ${scp_output_fn} 2>&1)
			typeset copy_return_code=$?

			sleep ${check_delay_s}
			echo "${fn} : will compare sha256 checksums after copy" >> "${scp_output_fn}" 2>&1 

			typeset local_file_checksum=`${remote_command} "sha256sum ${fn} | cut -d ' ' -f 1"`	
			typeset remote_file_checksum=`${remote_command} "sha256sum ${webdav_dir}/${file_basename} | cut -d ' ' -f 1"`	
			if [[  "${local_file_checksum}" != "${remote_file_checksum}" ]]; then
				# retry copying
				echo "Checksums after copy not same: local checksum: ${local_file_checksum}, remote checksum: ${remote_file_checksum}" >> ${scp_output_fn} 2>&1
				echo "${fn} : will retry copy to ${webdav_dir} using command ${remote_command} \"cp -f ${fn} ${webdav_dir}\"" >> "${scp_output_fn}" 2>&1 
				typeset retry_success=1
				typeset i=1
				while [ ${i} -le ${retries} ]
				do
					echo "${fn} : retry ${i} of ${retries}: copying to ${webdav_dir} using command ${remote_command} \"cp -f ${fn} ${webdav_dir}\"" >> "${scp_output_fn}" 2>&1 
					echo "${fn} : will compare sha256 checksums after retried copy" >> "${scp_output_fn}" 2>&1 

						# retry copying
						echo "Sleeping for ${retry_delay_s} seconds before retry" >> ${scp_output_fn} 2>&1
						sleep ${retry_delay_s}
						$(${remote_command} "cp -f ${fn} ${webdav_dir}" >> ${scp_output_fn} 2>&1)
						copy_return_code=$?

						echo "Sleeping for ${check_delay_s} seconds before check" >> ${scp_output_fn} 2>&1
						sleep ${check_delay_s}
						typeset local_file_checksum=`${remote_command} "sha256sum ${fn} | cut -d ' ' -f 1"`	
						typeset remote_file_checksum=`${remote_command} "sha256sum ${webdav_dir}/${file_basename} | cut -d ' ' -f 1"`	

						echo "copy return code: ${copy_return_code}" >> "${scp_output_fn}" 2>&1 
						echo "Local checksum: ${local_file_checksum}, remote checksum: ${remote_file_checksum}" >> ${scp_output_fn} 2>&1
						if [[ ${copy_return_code} -eq 0 && "${local_file_checksum}" == "${remote_file_checksum}" ]]; then
							# copy has been successfull
							retry_success=0
							echo "${fn} : retry ${i} of ${retries} successful: copied to ${webdav_dir} using command ${remote_command} \"cp -f ${fn} ${webdav_dir}\"" >> "${scp_output_fn}" 2>&1 
							break
						fi
						((i=i+1))
					done

					if [[ ${retry_success} -ne 0 ]]; then
						echo "${fn} : failed to copy to ${webdav_dir} after ${retries} retries using command ${remote_command} \"cp -f ${fn} ${webdav_dir}\"" >> "${scp_output_fn}" 2>&1 
						let failed_files_count=${failed_files_count}+1
					fi
				else
					echo "${fn} : Remote file checksum is the same as local. File copied successfully."  >> "${scp_output_fn}" 2>&1
				fi
		else
			echo "Remote file checksum is the same as local, will not copy ${fn} to ${webdav_dir}/${file_basename}"  >> "${scp_output_fn}" 2>&1
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
			echo "No valid files to be uploaded."
		else
			echo "${failed_files_count} files out of ${all_files_count} failed to be uploaded."
			echo "Check the output at ${scp_output_fn}."
		fi
		return 1
	else
		if [[ "${all_copied_files_count}" -eq "${all_files_count}" ]]; then
			echo "All ${all_files_count} file(s) uploaded successfully."
			return 0
		fi

		echo "Source and destination number of files differ."
		echo "Source files count: ${all_files_count}, destination files count: ${all_copied_files_count} ."
		return 1
	fi
}
