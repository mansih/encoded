#!/bin/bash
if [ -z $1 ]; then
    echo -e "\t\tFirst arg is mode.  live or test"
    exit 1
fi
mode="$1"
if [ -z $2 ]; then
    echo 'second arg aws credentials initial location.'
    exit 2
fi
if [ -z $3 ]; then
    echo 'third arg aws credentials final location.'
    exit 3
fi
read_aws_creds="$2/*"
write_aws_creds="$3"

echo -e "\tCopying aws creds from $read_aws_creds to $write_aws_creds"

if [ "$mode" == 'live' ]; then
    if [ -d "$write_aws_creds" ]; then
        sudo -u root rm -r "$write_aws_creds"
    fi
    sudo -u postgres mkdir -p "$write_aws_creds"
    echo 
    sudo -u root cp $read_aws_creds $write_aws_creds
    sudo -u root chown -R postgres:postgres $write_aws_creds
    exit 0
else
    rm -r "$write_aws_creds"
    mkdir -p "$write_aws_creds"
    cp -r $read_aws_creds $write_aws_creds
    exit 0
fi
exit 9999
