#!/bin/csh

if ( $# != 5 ) then
        echo "Expected 5 parameters: <directory> <backup_date> <pwd_file> <uncompressed_files_path> <compressed_files_path>"
        exit 1
endif

set compressed_datafile_ext="gz"

echo "Compressing the backup for date ${2}"
set datafile_date="$2"
set pwd_file="$3"
set uncompressed_path="$4"
set compressed_path="$5"
set split_size="32M"
set legal_fn=`basename "${1}"`
set full_compressed_fn="${compressed_path}/${legal_fn}-${datafile_date}.${compressed_datafile_ext}"
tar -C "$1" -cf - "$1" |  gpg --batch --yes --passphrase-fd 1 --passphrase-file "${pwd_file}" --output - -c | gzip -3 | split -b "${split_size}" -d -a 4 - "${full_compressed_fn}"_
if ($? == 0) then
        echo "`date`: Successfully encrypted and compressed directory ${1} on ${datafile_date} to ${full_compressed_fn}"
else
        echo "`date`: Failed to encrypt and compress directory ${1} for date ${datafile_date} to ${full_compressed_fn}"
endif
