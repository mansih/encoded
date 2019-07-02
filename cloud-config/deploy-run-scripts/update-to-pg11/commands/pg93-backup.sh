#!/bin/bash
mode=$1
if [ $mode -eq 1 ]; then
    echo 'Skipping wal-e backup since in test mode'
    exit 0
fi

if [ -z $2 ]; then
    echo 'Second arg is postgres main dir'
    exit 2
fi
pg_main="$2"

/opt/wal-e/bin/envfile --config ~postgres/.aws/credentials --section write-encoded-backups-dev --upper -- /opt/wal-e/bin/wal-e --s3-prefix="$(cat /etc/postgresql/9.3/main/wale_s3_prefix)" backup-push "$pg_main" 

