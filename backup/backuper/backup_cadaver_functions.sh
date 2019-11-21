#!/bin/ksh

get_cadaver_config () {

	if [[ $# -ne 3 ]]; then
		echo "Incorrect number of parameters for function get_cadaver_config"
		echo "Expected: 3, got: $#"
		echo "Terminating script"
		exit 1
	fi


	typeset config_to_return="open ${backup_server}\n\
cd ${2}\n\
lcd ${3}\n\
mput \"${1}\"\n\
exit"
	echo "${config_to_return}"
}


cadaver_backup() {

	if [[ $# -ne 1 ]]; then
		echo "Incorrect number of parameters for function cadaver_backup"
		echo "Expected: 1, got: $#"
		echo "Terminating script"
		exit 1
	fi

	typeset cadaver_config_fn=`mktemp /tmp/cadaver.conf.${backup_type}.XXXXXX`
	typeset cadaver_output_fn=`mktemp /tmp/cadaver.out.${backup_type}.XXXXXX`

	# saving cadaver ocnfig in a temporary fn
	echo "${1}" > "${cadaver_config_fn}"
	echo "Cadaver config: ${cadaver_config_fn}"
	echo "Cadaver stdout: ${cadaver_output_fn}"
	typeset output=$(cadaver -r ${cadaver_config_fn})
	echo "${output}" > "${cadaver_output_fn}"

	return 0 
}
