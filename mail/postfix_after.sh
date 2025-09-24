#!/bin/ksh

if [[ $# -ne 3 ]]; then
	echo "Expected 3 parameters: <new_mail_username> <domain> <root_maildir>"
	echo "Example:"
	echo "'test@example.com' 'example.com' 'example.com/test/'"
	echo "To launch for all mailboxes, do this:"
	echo "for i in \`doveadm user \'*\' | sed s/@example.com//g\`; do /path/to/postfix_after.sh \${i}@example.com example.com example.com/\${i}/; done"
	exit 1
fi

new_username="$1"
domain="$2"
root_maildir="$3"
mail_group="vmail"
mail_base_dir="/var/mail/vhosts"
vmail_user="vmail"
newdirbase="${mail_base_dir}/${root_maildir}"

id ${vmail_user} > /dev/null 2>&1

if [[ $? -ne 0 ]]; then
        echo "user ${vmail_user} does not exist"
        exit 1
fi


mkdir -p "${newdirbase}/Maildir"

if [[ $? -ne 0 ]]; then
	echo "creating new base mail dir failed"
	exit 1
fi

chown -R ${vmail_user}:${mail_group} "${newdirbase}"

if [[ $? -ne 0 ]]; then
        echo "chown base mail dir to ${vmail_user}:${mail_group} failed"
        exit 1
fi

chmod -R g+w "${newdirbase}"

if [[ $? -ne 0 ]]; then
        echo "chmod ase mail dir to g+w failed"
        exit 1
fi

