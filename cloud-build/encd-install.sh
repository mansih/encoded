#!/bin/bash
# Setup encoded app
# encoded user
# apt deps:

mkdir /srv/encoded
chown encoded:encoded /srv/encoded
cd /srv/encoded
sudo -u encoded git clone %(GIT_REPO)s . 
sudo -u encoded git checkout -b %(GIT_BRANCH)s origin/%(GIT_BRANCH)s
sudo pip3 install -U zc.buildout setuptools redis
sudo -u encoded buildout bootstrap
sudo -u encoded LANG=en_US.UTF-8 bin/buildout -c %(ROLE)s.cfg buildout:es-ip=%(ES_IP)s buildout:es-port=%(ES_PORT)s
sudo -u encoded bin/aws s3 cp --recursive s3://encoded-conf-prod/.aws .aws
until sudo -u postgres psql postgres -c ""; do sleep 10; done
sudo -u encoded sh -c 'cat /dev/urandom | head -c 256 | base64 > session-secret.b64'
sudo -u encoded bin/create-mapping production.ini --app-name app
sudo -u encoded bin/index-annotations production.ini --app-name app
if test "%(REGION_INDEX)s" = "False"
then
   sudo -u encoded cp /srv/encoded/etc/encoded-apache.conf /srv/encoded/etc/encoded-apache.conf.original
   sudo -u encoded sh -c "grep -v encoded\-regionindexer /srv/encoded/etc/encoded-apache.conf.original | grep -v _region > /srv/encoded/etc/encoded-apache.conf"
   sudo -u encoded cp /srv/encoded/base.ini /srv/encoded/base.ini.original
   sudo -u encoded sh -c "sed 's/vis_indexer, region_indexer/vis_indexer/' /srv/encoded/base.ini.original > /srv/encoded/base.ini"
fi
ln -s /srv/encoded/etc/encoded-apache.conf /etc/apache2/sites-available/encoded.conf
ln -s /srv/encoded/etc/logging-apache.conf /etc/apache2/conf-available/logging.conf
