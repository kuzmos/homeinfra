#!/bin/ksh

if [[ $# -ne 2 ]]; then
	echo "Expected 2 parameters: <new_vpn_username> <root_openvpn_dir>"
	exit 1
fi

new_vpn_username="$1"
root_openvpn_dir="$2"

pki_dir="${root_openvpn_dir}"/easy-rsa/3/pki
cd "${root_openvpn_dir}"/easy-rsa/3

"${root_openvpn_dir}"/easy-rsa/3/easyrsa --batch=1 --pki-dir=${pki_dir} --req-cn="${new_vpn_username}" gen-req "${new_vpn_username}" nopass

if [[ $? -ne 0 ]]; then
	echo "Generating certificate request failed"
	exit 1
fi

openssl req -in ${pki_dir}/reqs/"${new_vpn_username}".req -text -noout

if [[ $? -ne 0 ]]; then
	echo "Creating certificate request failed"
	exit 1
fi
openssl rsa -in ${pki_dir}/private/"${new_vpn_username}".key -check -noout

if [[ $? -ne 0 ]]; then
	echo "Creating key failed"
	exit 1
fi
"${root_openvpn_dir}"/easy-rsa/3/easyrsa --batch=1 --pki-dir=${pki_dir} show-req "${new_vpn_username}"
if [[ $? -ne 0 ]]; then
	echo "Disaplaying requirement failed"
	exit 1
fi
"${root_openvpn_dir}"/easy-rsa/3/easyrsa --batch=1 --pki-dir=${pki_dir} sign client "${new_vpn_username}"
if [[ $? -ne 0 ]]; then
	echo "Signing requirement failed"
	exit 1
fi
openssl x509 -in ${pki_dir}/issued/"${new_vpn_username}".crt -text -noout
if [[ $? -ne 0 ]]; then
	echo "Creating crt file failed"
	exit 1
fi
openssl pkcs12 -export -in "${pki_dir}"/issued/"${new_vpn_username}".crt -inkey "${pki_dir}"/private/"${new_vpn_username}".key -certfile "${root_openvpn_dir}"/certs/vpn-ca.crt -name "${new_vpn_username}" -out "${root_openvpn_dir}"/configs/"${new_vpn_username}".p12 
if [[ $? -ne 0 ]]; then
	echo "Creating p12 file failed"
	exit 1
fi

echo "Please copy files ${root_openvpn_dir}/configs/${new_vpn_username}.p12 and ${root_openvpn_dir}/configs/vpnclient-mobile.conf to client device"

