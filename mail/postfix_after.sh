#!/bin/ksh

if [[ $# -ne 4 ]]; then
	echo "Expected 3 parameters: <new_mail_username> <domain> <root_maildir> <quota>"
	exit 1
fi

new_username="$1"
domain="$2"
root_maildir="$3"
mail_group="mailers"

mkdir "${root_maildir}"/"${new_username}"/sieve

if [[ $? -ne 0 ]]; then
	echo "creating sieve dir failed"
	exit 1
fi

touch "${root_maildir}"/"${new_username}"/sieve/managesieve.sieve

if [[ $? -ne 0 ]]; then
	echo "creating managesieve.sieve file failed"
	exit 1
fi

ln -s "${root_maildir}"/"${new_username}"/sieve/managesieve.sieve "${root_maildir}"/"${new_username}"/.dovecot.sieve

if [[ $? -ne 0 ]]; then
	        echo 'creating symlink "${root_maildir}"/"${new_username}"/.dovecot.sieve to "${root_maildir}"/"${new_username}"/sieve/managesieve.sieve failed'
		        exit 1
fi

chown -h "${new_username}":"${mail_group}" "${root_maildir}"/"${new_username}"/.dovecot.sieve

if [[ $? -ne 0 ]]; then
	        echo 'changing symlink "${root_maildir}"/"${new_username}"/.dovecot.sieve owner to "${new_username}" failed'
		        exit 1
fi
