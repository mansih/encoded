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

AWS_CREDS_DIR='/var/lib/postgresql/.aws'
AWS_PROFILE='default'
PG_CONF='/etc/postgresql/9.3/main'
PG_DATA='/var/lib/postgresql/9.3/main'
WALE_DIR='/opt/wal-e'
WALE_BIN="$WALE_DIR/bin"
WALE_REQS='/home/ubuntu/encoded/wal-e-requirements.txt'

# create custom.conf
echo 'hot_standby = on' >> "$PG_CONF/custom.conf"
echo 'max_standby_archive_delay = -1' >> "$PG_CONF/custom.conf"
echo 'wal_level = hot_standby' >> "$PG_CONF/custom.conf"
echo 'archive_mode = on' >> "$PG_CONF/custom.conf"
echo 'archive_timeout = 60' >> "$PG_CONF/custom.conf"
echo 'checkpoint_timeout = 1h' >> "$PG_CONF/custom.conf"
# create demo.conf
echo 'archive_mode = off' >> "$PG_CONF/demo.conf"
# create master.conf
echo "archive_command = '$WALE_BIN/envfile --config $AWS_CREDS_DIR/credentials --section $AWS_PROFILE --upper -- $WALE_BIN/wal-e --s3-prefix=$WALE_S3_PREFIX wal-push \"%p\"'" >> "$PG_CONF/master.conf"
# create recovery.conf
echo "recovery_target_timeline = 'latest'" >> "$PG_CONF/recovery.conf"
echo "restore_command = '$WALE_BIN/wal-e --aws-instance-profile --s3-prefix=$WALE_S3_PREFIX wal-fetch \"%f\" \"%p\"'" >> "$PG_CONF/recovery.conf"
echo "standby_mode = $standby_mode" >> "$PG_CONF/recovery.conf"
# create postgres conf
echo "include 'custom.conf'" >> "$PG_CONF/postgresql.conf"
if [ "$ROLE" == 'candidate' ]; then
    echo 'Candidate'
else
    echo "include 'demo.conf'" >> "$PG_CONF/postgresql.conf"
fi
# create wal-e prefix
echo "$WALE_S3_PREFIX" >> "$PG_CONF/wale_s3_prefix"
sudo -u root chown postgres:postgres "$PG_CONF/wale_s3_prefix"
sudo -u root chown postgres:postgres "$PG_CONF/custom.conf"
sudo -u root chown postgres:postgres "$PG_CONF/demo.conf"
sudo -u root chown postgres:postgres "$PG_CONF/master.conf"
sudo -u root chown postgres:postgres "$PG_CONF/postgresql.conf"
sudo -u root chown postgres:postgres "$PG_CONF/recovery.conf"
sudo -u postgres createuser encoded
sudo -u postgres createdb --owner=encoded encoded

sudo -u root mkdir "$WALE_DIR"
sudo -u root chown postgres:postgres "$WALE_DIR"
cd "$WALE_DIR"
cp $WALE_REQS ./wal-e-requirements.txt
sudo -u postgres virtualenv --python=python2.7 ./
sudo -u postgres "$WALE_BIN/pip" install -r ./wal-e-requirements.txt
sudo -u postgres /etc/init.d/postgresql stop
sudo -u postgres "$WALE_BIN/wal-e" --aws-instance-profile --s3-prefix="$WALE_S3_PREFIX" backup-fetch "$PG_DATA" LATEST
sudo -u postgres ln -s "$PG_CONF/recovery.conf" "$PG_DATA/"
sudo -u postgres /etc/init.d/postgresql start
until sudo -u postgres psql postgres -c ""; do sleep 10; done
