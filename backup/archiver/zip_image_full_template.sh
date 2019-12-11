#!/bin/csh

if ( $# != 5 ) then
        echo "Expected 5 parameters: <dataset_name> <backup_date> <pwd_file> <uncompressed_files_path> <compressed_files_path>"
        exit 1
endif

set datafile_ext="bak"
set compressed_datafile_ext="gz"

echo "Compressing the backup for date ${2}"
set datafile_date="$2"
set pwd_file="$3"
set uncompressed_path="$4"
set compressed_path="$5"
#echo "Compressing the backup for today"
#set datafile_date=`date +"%Y%m%d"`

set split_size="32M"
set legal_fn=`echo "${1}" | sed 's/\//#/g'`
set full_uncompressed_fn="${uncompressed_path}/${legal_fn}-${datafile_date}.${datafile_ext}"
set full_compressed_fn="${compressed_path}/${legal_fn}-${datafile_date}.${compressed_datafile_ext}"
gpg --batch --yes --passphrase-fd 1 --passphrase-file ${pwd_file} --output - -c ${full_uncompressed_fn} | gzip -3 | split -b ${split_size} -d -a 4 - ${full_compressed_fn}_
if ($? == 0) then
        echo "Successfully encrypted and compressed dataset ${1} on ${datafile_date} to ${full_compressed_fn}"
        echo "Deleting uncompressed backup ${full_uncompressed_fn} to save space"
        rm ${full_uncompressed_fn}
else
        echo "Failed to encrypt and compress ${1} backup for date ${datafile_date} to ${full_compressed_fn}"
endif
