#!/bin/ksh

if [[ $# -ne 4 ]]; then
	echo "Expected 4 parameters: <new_mail_username> <domain> <root_maildir> <quota>"
	exit 1
fi

new_username="$1"
domain="$2"
root_maildir="$3"
mail_group="mailers"
mail_base_dir="/var/mail/vhosts"
vmail_user="vmail"
newdirbase="${mail_base_dir}/${root_maildir}"

mkdir "${newdirbase}"

if [[ $? -ne 0 ]]; then
	echo "creating new base mail dir failed"
	exit 1
fi


mkdir "${newdirbase}"/sieve

if [[ $? -ne 0 ]]; then
	echo "creating sieve dir failed"
	exit 1
fi

touch "${newdirbase}"/sieve/managesieve.sieve

if [[ $? -ne 0 ]]; then
	echo "creating managesieve.sieve file failed"
	exit 1
fi

ln -s "${newdirbase}"/sieve/managesieve.sieve "${newdirbase}"/.dovecot.sieve

if [[ $? -ne 0 ]]; then
	        echo 'creating symlink "${newdirbase}"/.dovecot.sieve to "${newdirbase}"/sieve/managesieve.sieve failed'
		        exit 1
fi

chown -h "${vmail_user}":"${mail_group}" "${newdirbase}"/.dovecot.sieve

if [[ $? -ne 0 ]]; then
	        echo 'changing symlink "${newdirbase}"/.dovecot.sieve owner to "${vmail_user}i:${mail_group}" failed'
		        exit 1
fi
