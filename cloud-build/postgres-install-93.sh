#!/bin/bash
# Setup postgres
# postgres user
# apt deps:
#	postgresql-9.3

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
