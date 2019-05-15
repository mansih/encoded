#!/bin/bash
### Run first after cloud init installation
# For general items that did not fit/belong in cloud init
# postgres user
# apt deps:
# 	postgresql-9.3

set -ex
chown postgres:postgres /etc/postgresql/9.3/main/*.conf
echo "include 'custom.conf'" >> /etc/postgresql/9.3/main/postgresql.conf
if test "%(ROLE)s" != "candidate"
then
  echo "standby_mode = off" >> /etc/postgresql/9.3/main/recovery.conf
  echo "include 'demo.conf'" >> /etc/postgresql/9.3/main/postgresql.conf
fi
sudo -u postgres createuser encoded
sudo -u postgres createdb --owner=encoded encoded

# Add team ssh public keys from s3
mv /home/ubuntu/.ssh/authorized_keys /home/ubuntu/.ssh/authorized_keys2
aws s3 cp --region=us-west-2 s3://encoded-conf-prod/ssh-keys/demo-authorized_keys /home/ubuntu/.ssh/authorized_keys
