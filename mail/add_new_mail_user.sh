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

chown -R "${new_username}":"${mail_group}"  "${root_maildir}"/"${new_username}"

if [[ $? -ne 0 ]]; then
        echo "changing maildir owner to ${new_username}:${mail_group} failed"
        exit 1
fi

chmod -R g+r "${root_maildir}"/"${new_username}"

if [[ $? -ne 0 ]]; then
        echo "adding read permissions to maildir ${root_maildir}/${new_username} failed"
        exit 1
fi

ln -s "${root_maildir}"/"${new_username}"/Maildir /home/"${new_username}"/Maildir

if [[ $? -ne 0 ]]; then
        echo "creating symlink /home/${new_username}/Maildir to ${root_maildir}/${new_username}/Maildir failed"
        exit 1
fi

chown -h "${new_username}":"${mail_group}" /home/"${new_username}"/Maildir

if [[ $? -ne 0 ]]; then
        echo "changing symlink /home/${new_username}/Maildir owner to ${new_username} failed"
        exit 1
fi

ln -s "${root_maildir}"/"${new_username}"/sieve /home/"${new_username}"/sieve

if [[ $? -ne 0 ]]; then
        echo "creating symlink /home/${new_username}/sieve to ${root_maildir}/${new_username}/sieve failed"
        exit 1
fi

chown -h "${new_username}":"${mail_group}" /home/"${new_username}"/sieve

if [[ $? -ne 0 ]]; then
        echo "changing symlink /home/${new_username}/sieve owner to ${new_username} failed"
        exit 1
fi

ln -s "${root_maildir}"/"${new_username}"/sieve /home/"${new_username}"/sieve

if [[ $? -ne 0 ]]; then
        echo "creating symlink /home/${new_username}/sieve to ${root_maildir}/${new_username}/sieve failed"
        exit 1
fi

chown -h "${new_username}":"${mail_group}" /home/"${new_username}"/sieve

if [[ $? -ne 0 ]]; then
        echo "changing symlink /home/${new_username}/sieve owner to ${new_username} failed"
        exit 1
fi

ln -s "${root_maildir}"/"${new_username}"/sieve/managesieve.sieve /home/"${new_username}"/.dovecot.sieve

if [[ $? -ne 0 ]]; then
        echo "creating symlink /home/${new_username}/.dovecot.sieve to ${root_maildir}/${new_username}/sieve/managesieve.sieve failed"
        exit 1
fi

chown -h "${new_username}":"${mail_group}" /home/"${new_username}"/.dovecot.sieve

if [[ $? -ne 0 ]]; then
        echo "changing symlink /home/${new_username}/.dovecot.sieve owner to ${new_username} failed"
        exit 1
fi

ln -s "${root_maildir}"/"${new_username}"/sieve/managesieve.sieve "${root_maildir}"/"${new_username}"/.dovecot.sieve

if [[ $? -ne 0 ]]; then
        echo "creating symlink ${root_maildir}/${new_username}/.dovecot.sieve to ${root_maildir}/${new_username}/sieve/managesieve.sieve failed"
        exit 1
fi

chown -h "${new_username}":"${mail_group}" "${root_maildir}"/"${new_username}"/.dovecot.sieve

if [[ $? -ne 0 ]]; then
        echo "changing symlink ${root_maildir}/${new_username}/.dovecot.sieve owner to ${new_username} failed"
        exit 1
fi

echo "Mail and filter dirs structure for new user ${new_username} created successfully. Run \"passwd ${new_username}\" as root to set new user mail password"
