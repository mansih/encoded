#!/bin/bash
if [ -z $1 ]; then
    echo "First arg is mode.  live or test"
    exit 1
fi
if [ -z $2 ]; then
    echo 'Second arg is wale url backup directory.'
    exit 2
fi
mode="$1"
backup_dir="$2"
test_files="$3"
if [ -z $3 ]; then
    test_files="./test-files" 
fi

echo -e "\tSetting wal-e prefix to $backup_dir"

# Set wale prefix path to set
wale_s3_prefix_path="$test_files/wale_s3_prefix"
if [ "$mode" == 'live' ]; then
    wale_s3_prefix_path='/etc/postgresql/9.3/main/wale_s3_prefix'
fi

# Remove Current wal-e file if it exists
old_wale_s3_prefix=''
if [ -f "$wale_s3_prefix_path" ]; then
    old_wale_s3_prefix="$(cat $wale_s3_prefix_path)"
    rm "$wale_s3_prefix_path"
fi

# Create new wal-e file with prefix
echo $backup_dir >> $wale_s3_prefix_path

# Check results
wale_s3_prefix="$(cat $wale_s3_prefix_path)"
if [ -z $wale_s3_prefix ]; then
    echo -e '\t\tFailure: Wale prefix is empty'
    exit 3
else
    echo -e "\t\tPassed: Wal-e prefix changed from '$old_wale_s3_prefix' to '$wale_s3_prefix'"
    exit 0
fi
exit 9999
