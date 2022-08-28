#!/bin/csh

if ( $# != 6 ) then
        echo "Expected 6 parameters: <dataset_name> <prev_date> <current_date> <pwd_file> <uncompressed_files_path> <compressed_files_path>"
        exit 1
endif

set datafile_ext="bak"
set compressed_datafile_ext="gz"

#	set datafile_date=`gdate +"%Y%m%d"`
#	set datafile_prev_date=`gdate +"%Y%m%d" -d "1 week ago"`
set datafile_prev_date="$2"
set datafile_date="$3"
set pwd_file="$4"
set uncompressed_path="$5"
set compressed_path="$6"

set split_size="128M"
set legal_fn=`echo "$1" | sed 's/\//#/g'`
set full_uncompressed_fn="${uncompressed_path}/${legal_fn}-${datafile_prev_date}-${datafile_date}.${datafile_ext}"
set full_compressed_fn="${compressed_path}/${legal_fn}-${datafile_prev_date}-${datafile_date}.${compressed_datafile_ext}"
gpg --batch --yes --passphrase-fd 1 --passphrase-file "$pwd_file" --output - -c "$full_uncompressed_fn" | gzip -3 | split -b "$split_size" -d -a 4 - "$full_compressed_fn"_
if ($? == 0) then
        echo "`date`: Successfully encrypted and compressed dataset ${1} differential backup for dates ${datafile_prev_date} and ${datafile_date} to ${full_compressed_fn}"
	echo "Total `ls '${full_compressed_fn}'* | wc -l | xargs` file(s), with size `du -hc '${full_compressed_fn}'* | tail -1 | cut -f 1`"
        echo "Deleting uncompressed backup ${full_uncompressed_fn} to save space"
        rm "$full_uncompressed_fn"
else
        echo "Failed to encrypt and compress ${1} differential backup for dates ${datafile_prev_date} and ${datafile_date} to ${full_compressed_fn}"
endif
