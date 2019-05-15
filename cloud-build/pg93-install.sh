#!/bin/bash
# Setup postgres
# postgres user
# apt deps:
#   postgresql-9.3


# create custom.conf
echo 'hot_standby = on' >> /etc/postgresql/9.3/main/custom.conf
echo 'max_standby_archive_delay = -1' >> /etc/postgresql/9.3/main/custom.conf
echo 'wal_level = hot_standby' >> /etc/postgresql/9.3/main/custom.conf
echo 'archive_mode = on' >> /etc/postgresql/9.3/main/custom.conf
echo 'archive_timeout = 60' >> /etc/postgresql/9.3/main/custom.conf
echo 'checkpoint_timeout = 1h' >> /etc/postgresql/9.3/main/custom.conf
echo 'hot_standby = on' >> /etc/postgresql/9.3/main/custom.conf
# create demo.conf
echo 'archive_mode = off' >> /etc/postgresql/9.3/main/demo.conf
# create master.conf
echo "archive_command = '/opt/wal-e/bin/envfile --config ~postgres/.aws/credentials --section default --upper -- /opt/wal-e/bin/wal-e --s3-prefix=\"$(cat /etc/postgresql/9.3/main/wale_s3_prefix)\" wal-push \"%p\"'" >> /etc/postgresql/9.3/main/master.conf
# create demo.conf
echo "recovery_target_timeline = 'latest'" >> /etc/postgresql/9.3/main/recovery.conf
echo "restore_command = '/opt/wal-e/bin/wal-e --aws-instance-profile --s3-prefix=\"$(cat /etc/postgresql/9.3/main/wale_s3_prefix)\" wal-fetch \"%f\" \"%p\"'" >> /etc/postgresql/9.3/main/recovery.conf
echo "standby_mode = on" >> /etc/postgresql/9.3/main/recovery.conf
echo "s3://encoded-backups-prod/production" >> /etc/postgresql/9.3/main/wale_s3_prefix

chown postgres:postgres /etc/postgresql/9.3/main/*.conf
echo "include 'custom.conf'" >> /etc/postgresql/9.3/main/postgresql.conf
echo "standby_mode = off" >> /etc/postgresql/9.3/main/recovery.conf
echo "include 'demo.conf'" >> /etc/postgresql/9.3/main/postgresql.conf
sudo -u postgres createuser encoded
sudo -u postgres createdb --owner=encoded encoded
