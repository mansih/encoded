#!/bin/bash
# Setup postgres
# postgres user
# apt deps:
#   postgresql-9.3
#   python2.7-dev # wal-e
#   lzop # wal-e

standby_mode="$1"
ROLE="$2"
WALE_S3_PREFIX="$3"

# DeBUG
standby_mode='off'
ROLE='demo'
WALE_S3_PREFIX='s3://encoded-backups-dev/production-pg11'
# DeBUG^

AWS_CREDS_DIR='/var/lib/postgresql/.aws'
AWS_PROFILE='write-encoded-backups-dev'

PG_CONF_SRC='/home/ubuntu/encoded/cloud-config/deploy-run-scripts/pg-conf'
PG_CONF_DEST='/etc/postgresql/11/main'

PG_CONF='/etc/postgresql/11/main'
PG_DATA='/var/lib/postgresql/11/main'
WALE_DIR='/opt/pg-wal-e'
WALE_VENV="$WALE_DIR/.py343-wal-e"
WALE_BIN="$WALE_VENV/bin"
WALE_REQS='/home/ubuntu/encoded/wal-e-requirements-py3.txt'
WALE_ENV='/etc/wal-e.d/env'

function copy_with_permission {
    src_file="$1/$3"
    dest_file="$2/$3"
    sudo -u root cp "$src_file" "$dest_file"
    sudo -u root chown postgres:postgres "$dest_file"
}

if [ 0 -eq 0 ]; then
    # PG Conf
    echo "$WALE_S3_PREFIX" >> "$PG_CONF_SRC/WALE_S3_PREFIX"
    echo "archive_command = '$WALE_BIN/envdir $WALE_ENV $WALE_BIN/wal-e --s3-prefix=$WALE_S3_PREFIX wal-push \"%p\"'" >> "$PG_CONF_SRC/master.conf"
    echo "restore_command = '$WALE_BIN/envdir $WALE_ENV $WALE_BIN/wal-e --aws-instance-profile --s3-prefix=$WALE_S3_PREFIX wal-fetch \"%f\" \"%p\"'" >> "$PG_CONF_SRC/recovery.conf"
    for filename in 'custom.conf' 'demo.conf' 'master.conf' 'recovery.conf' 'WALE_S3_PREFIX'; do
        copy_with_permission "$PG_CONF_SRC" "$PG_CONF_DEST" "$filename"
    done
    sudo -u postgres ln -s "$PG_CONF/recovery.conf" "$PG_DATA/"
    pg_conf="$PG_CONF/postgresql.conf"
    sudo -u root chown postgres:postgres "$pg_conf"
    echo "include 'custom.conf'" | sudo -u postgres tee -a "$pg_conf"
    if [ ! "$ROLE" == 'candidate' ]; then
        echo "include 'demo.conf'" | sudo -u postgres tee -a "$pg_conf"
    fi

    # PG AWS Creds
    sudo -u postgres /usr/bin/aws s3 cp --region=us-west-2 --recursive s3://encoded-conf-prod/.aws "$AWS_CREDS_DIR"

    # WALE Environment
    sudo -u root mkdir -p "$WALE_ENV"
    sudo -u root chown postgres:postgres "$WALE_ENV"
    for filename in 'AWS_ACCESS_KEY_ID' 'AWS_SECRET_ACCESS_KEY' 'AWS_REGION'; do
        copy_with_permission "$AWS_CREDS_DIR" "$WALE_ENV" "$filename"
    done
    copy_with_permission "$PG_CONF_DEST" "$WALE_ENV" 'WALE_S3_PREFIX'
    exit
fi

if [ 0 -eq 0 ]; then
    # PG Setup
    sudo -u postgres createuser encoded
    sudo -u postgres createdb --owner=encoded encoded
fi

# WALE Install
if [ 0 -eq 0 ]; then
    sudo -u root rm -r "$WALE_DIR"
    sudo -u root mkdir -p "$WALE_DIR"
    sudo -u root chown postgres:postgres "$WALE_DIR"
    sudo -u root cp "$WALE_REQS" "$WALE_DIR/wal-e-requirements.txt"
    sudo -u root chown postgres:postgres "$WALE_DIR/wal-e-requirements.txt"
    sudo -H -u postgres python3 -m venv "$WALE_VENV"
    sudo -H -u postgres "$WALE_BIN/pip" install pip setuptools boto awscli --upgrade
    sudo -H -u postgres "$WALE_BIN/pip" install -r "$WALE_DIR/wal-e-requirements.txt"
    sudo -u postgres git clone https://github.com/wal-e/wal-e.git "$WALE_DIR/wal-e"
    sudo -H -u postgres "$WALE_BIN/pip" install -e "$WALE_DIR/wal-e"
fi

if [ 0 -eq 0 ]; then
    # PG Fetch backup
    sudo -u postgres pg_ctlcluster 11 main stop
    sudo -u postgres "$WALE_BIN/envdir" "$WALE_ENV" "$WALE_BIN/wal-e" --aws-instance-profile --s3-prefix="$WALE_S3_PREFIX" backup-fetch "$PG_DATA" LATEST
    # DEBUG: Ubove command with test vars:
    # $sudo -u postgres /opt/pg-wal-e/.py343-wal-e/bin/envdir /etc/wal-e.d/env /opt/pg-wal-e/.py343-wal-e/bin/wal-e --aws-instance-profile --s3-prefix=s3://encoded-backups-dev/production-pg11 backup-fetch /var/lib/postgresql/11/main LATEST

    # PG Restart and wait
    sudo -u postgres pg_ctlcluster 11 main start
    psql_cnt=0
    until sudo -u postgres psql postgres -c ""; do 
        psql_cnt=$((psql_cnt+1))
        sleep 10; 
        if [ $psql_cnt -gt 6 ]; then
            echo 'INSTALL FAILURE(pg11-install.sh): Postgres did not restart'
            exit 123
        fi
    done
fi
