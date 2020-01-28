#!/bin/ksh

if [[ $# -ne 3 ]]; then
	echo "Expected 3 parameters: <new_mail_username> <root_maildir> <mail_group>"
	exit 1
fi

new_username="$1"
root_maildir="$2"
mail_group="$3"

# create new openbsd user
useradd -b /home -m -s nologin "${new_username}"
if [[ $? -ne 0 ]]; then
	echo "useradd failed"
	exit 1
fi

mkdir -p "${root_maildir}"/"${new_username}"/Maildir

if [[ $? -ne 0 ]]; then
	echo "creating maildir failed"
	exit 1
fi

chown -R "${new_username}":"${mail_group}"  "${root_maildir}"/"${new_username}"

if [[ $? -ne 0 ]]; then
        echo "changing maildir owner to ${new_username}:${mail_group} failed"
        exit 1
fi

ln -s "${root_maildir}"/"${new_username}"/Maildir  /home/"${new_username}"/Maildir

if [[ $? -ne 0 ]]; then
        echo 'creating symlink /home/"${new_username}"/Maildir to "${root_maildir}"/"${new_username}"/Maildir failed'
        exit 1
fi
