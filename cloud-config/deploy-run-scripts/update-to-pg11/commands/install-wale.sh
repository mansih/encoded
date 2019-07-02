# Wal-E - Install
sudo apt-get install python3.4-venv
sudo -u postgres /usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data start
sudo -u root mkdir /opt/pg-wal-e
sudo -u root chown -R postgres:postgres /opt/pg-wal-e
sudo -u root sudo -u root mkdir -p /etc/wal-e.d/env
sudo -u root chown -R postgres:postgres /etc/wal-e.d
if [ "$2" == 'prod' ]; then
    sudo -u postgres /usr/bin/aws s3 cp --region=us-west-2 --recursive s3://encoded-conf-prod/.aws /var/lib/postgresql/.aws
    sudo -u postgres cp /var/lib/postgresql/.aws/credentials_key /etc/wal-e.d/env/AWS_ACCESS_KEY_ID
    sudo -u postgres cp /var/lib/postgresql/.aws/credentials_secret /etc/wal-e.d/env/AWS_SECRET_ACCESS_KEY
    sudo -u postgres cp /etc/postgresql/11/main/wale_s3_prefix /etc/wal-e.d/env/WALE_S3_PREFIX
else
    sudo -u postgres cp /var/lib/postgresql/.aws/credentials_key /etc/wal-e.d/env/AWS_ACCESS_KEY_ID
    sudo -u postgres cp /var/lib/postgresql/.aws/credentials_secret /etc/wal-e.d/env/AWS_SECRET_ACCESS_KEY
    sudo -u postgres cp /etc/postgresql/9.3/main/wale_s3_prefix /etc/wal-e.d/env/WALE_S3_PREFIX
fi
echo -n "us-west-2" | sudo -u postgres tee -a /etc/wal-e.d/env/AWS_REGION
sudo -u postgres python3 -m venv /opt/pg-wal-e/.py343-wal-e
sudo apt-get remove -y awscli
sudo -u postgres /opt/pg-wal-e/.py343-wal-e/bin/pip install pip setuptools boto awscli --upgrade
sudo -u root cp /home/ubuntu/encoded/wal-e-requirements-py3.txt /opt/pg-wal-e
sudo -u root chown postgres:postgres /opt/pg-wal-e/wal-e-requirements-py3.txt

echo 'The following installation must be done manually as postgres user at the momement'
echo '/opt/pg-wal-e/.py343-wal-e/bin/pip install -r /opt/pg-wal-e/wal-e-requirements-py3.txt'
echo '# sudo -u postgres git clone https://github.com/wal-e/wal-e.git /opt/pg-wal-e/wal-e'
echo '/opt/pg-wal-e/.py343-wal-e/bin/pip install -e /opt/pg-wal-e/wal-e'

echo -e "\nAfter running these commands rerun the './update-pg93to11.sh live demo waleokay'"
