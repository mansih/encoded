#!/bin/bash
### Upgrade encoded postgres 9.3 database to postgres 11 

commands_dir='./commands'
test_files="$commands_dir/test-files"

# Input Args
mode='test'
if [ "$1" == 'live' ]; then
    sudo service apache2 stop
    mode='live'
fi
# Aws account name
account='demo'
if [ "$2" == 'prod' ]; then
    account='prod'
fi
# Aws account name
waleokay=1
if [ "$3" == 'waleokay' ]; then
    waleokay=0
fi
echo "Running in '$mode' mode on '$account' account."

# Set run vars
aws_read_credentials="$test_files/aws-creds-postgres"
aws_write_credentials="$test_files/tmp-aws-wrote"
backup_backup='production-pg93pre11'
current_backup='production'
new_backup='production-pg11'
s3_url='s3://encoded-backups-dev'
if [ "$mode" == 'live' ]; then
    aws_read_credentials='/home/ubuntu/.pg-aws'
    aws_write_credentials="/var/lib/postgresql/.aws"
    if [ "$account" == 'prod' ]; then
        s3_url='s3://encoded-backups-prod'
    fi
fi
backup_backup="$s3_url/$backup_backup"
current_backup="$s3_url/$current_backup"
new_backup="$s3_url/$new_backup"


# THIS IS THE FINAL STEP AND SHOULD ONLY RUN AFTER WALEOKAY
# THIS IS THE FINAL STEP AND SHOULD ONLY RUN AFTER WALEOKAY
# THIS IS THE FINAL STEP AND SHOULD ONLY RUN AFTER WALEOKAY
if [ $waleokay -eq 0 ]; then
    echo -e "\nWALEOKAY Back up postgres 11 to new location"
    if [ "$mode" == 'live' ]; then
        echo -e '\tSet for pg 11 backup push'
        sudo -u root $commands_dir/set-wale-prefix.sh "$mode" "$new_backup" "$test_files"
        if [ $? -ne 0 ]; then
            echo "backup 11 error mode=$mode command 'set-wale-prefix.sh'"
            exit 200
        fi
        sudo -u postgres $commands_dir/set-pg-conf.sh "$mode" 'master' "$test_files" 'pg11'
        if [ $? -ne 0 ]; then
            echo "backup 11 error mode=$mode command 'set-pg-conf.sh'"
            exit 201
        fi
        echo -e '\tMake pg 11 backup push'
        sudo -u postgres /opt/pg-wal-e/.py343-wal-e/bin/envdir /etc/wal-e.d/env /opt/pg-wal-e/.py343-wal-e/bin/wal-e --s3-prefix="$(cat /etc/postgresql/9.3/main/wale_s3_prefix)" backup-push /usr/local/pgsql/data
        if [ $? -ne 0 ]; then
            echo "backup 11 error mode=$mode command 'push'"
            exit 299
        fi
        exit 0
    fi
    exit
fi

# Step 1 and so forth
# Step 1 and so forth
# Step 1 and so forth
if [ 0 -eq 0 ]; then
    echo -e '\nChecking aws credentials'
    if [ -d "$aws_read_credentials" ]; then
        if [ ! -f "$aws_read_credentials/credentials" ]; then
            echo -e "\tFailure: Aws credentials '$aws_read_credentials/credentials does not exist."
            exit 21 
        fi
        if [ ! -f "$aws_read_credentials/credentials_key" ]; then
            echo -e "\tFailure: Aws credentials '$aws_read_credentials/credentials_key does not exist."
            exit 22
        fi
        if [ ! -f "$aws_read_credentials/credentials_secret" ]; then
            echo -e "\tFailure: Aws credentials '$aws_read_credentials/credentials_secret does not exist."
            exit 23
        fi
        echo -e "\tUsing aws credentials: '$aws_read_credentials'"
    else
        echo -e "\tFailure: Aws credentials '$aws_read_credentials' do not exist."
        exit 20
    fi
fi

if [ 0 -eq 0 ]; then
    echo -e "\nBackup current 9.3 db in: $aws_bucket_credentials"
    if [ "$mode" == 'live' ]; then
        sudo -u root $commands_dir/set-wale-prefix.sh "$mode" "$backup_backup" "$test_files"
        if [ $? -ne 0 ]; then
            echo "ERROR mode=$mode command 'set-wale-prefix.sh'"
            exit 100
        fi
        sudo -u postgres $commands_dir/set-pg-conf.sh "$mode" 'master' "$test_files"
        if [ $? -ne 0 ]; then
            echo "ERROR mode=$mode command 'set-pg-conf.sh'"
            exit 101
        fi
        sudo -u ubuntu $commands_dir/set-aws-creds.sh "$mode" "$aws_read_credentials" "$aws_write_credentials"
        if [ $? -ne 0 ]; then
            echo "ERROR mode=$mode command 'set-aws-creds.sh'"
            exit 103
        fi
        sudo -u postgres /opt/wal-e/bin/envfile --config ~postgres/.aws/credentials --section write-encoded-backups-dev --upper -- /opt/wal-e/bin/wal-e --s3-prefix="$(cat /etc/postgresql/9.3/main/wale_s3_prefix)" backup-push '/var/lib/postgresql/9.3/main'
        if [ $? -ne 0 ]; then
            echo "ERROR mode=$mode command 'wale back up push'"
            exit 104
        fi
    else
        $commands_dir/set-wale-prefix.sh "$mode" "$backup_backup" "$test_files"
        if [ $? -ne 0 ]; then
            echo "ERROR mode=$mode command 'set-wale-prefix.sh'"
            exit 199
        fi
        $commands_dir/set-pg-conf.sh "$mode" 'master' "$test_files"
        if [ $? -ne 0 ]; then
            echo "ERROR mode=$mode command 'set-pg-conf.sh'"
            exit 198
        fi
        $commands_dir/set-aws-creds.sh "$mode" "$aws_read_credentials" "$aws_write_credentials"
        if [ $? -ne 0 ]; then
            echo "ERROR mode=$mode command 'set-aws-creds.sh'"
            exit 197
        fi
        echo -e '\tTest: Undoing wale prefix, pg conf, and aws creds'
        $commands_dir/set-wale-prefix.sh "$mode" "$current_backup" "$test_files"
        if [ $? -ne 0 ]; then
            echo "Undo ERROR mode=$mode command 'set-wale-prefix.sh'"
            exit 189
        fi
        $commands_dir/set-pg-conf.sh "$mode" 'demo' "$test_files"
        if [ $? -ne 0 ]; then
            echo "Undo ERROR mode=$mode command 'set-pg-conf.sh'"
            exit 188
        fi
        rm -r "$aws_write_credentials"
        if [ $? -ne 0 ]; then
            echo "Undo ERROR mode=$mode command 'remove test aws cred dir'"
            exit 187
        fi
    fi
fi

if [ 0 -eq 0 ]; then
    echo -e "\nInstall postgres 11"
    if [ "$mode" == 'live' ]; then
        echo -e '\tinstall pg11 deps'
        sudo apt-get install -y libreadline-dev
        
        echo - '\tdownload pg11'
        pg11_name='postgresql-11.2'
        pg11_dl="https://ftp.postgresql.org/pub/source/v11.2/$pg11_name.tar.gz"
        pg11_dl_loc="/var/lib/postgresql/$pg11_name.tar.gz"
        pg11_untar_loc="/var/lib/postgresql"
        sudo -u postgres curl -o "$pg11_dl_loc" "$pg11_dl"
        sudo -u postgres tar xvzf $pg11_dl_loc -C $pg11_untar_loc
        
        echo -e "\tinstall pg11: $pg11_untar_loc"
        cd "$pg11_untar_loc/$pg11_name"
        sudo -u postgres ./configure
        sudo -u postgres make
        sudo -u root make install
        sudo -u root mkdir /usr/local/pgsql/data
        sudo -u root chown postgres /usr/local/pgsql/data
        sudo -u postgres /usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data

        echo -e "\tCopy over 93 config to 11"
        sudo -u postgres cp /etc/postgresql/9.3/main/master.conf /usr/local/pgsql/data/master.conf
        sudo -u postgres cp /etc/postgresql/9.3/main/custom.conf /usr/local/pgsql/data/custom.conf
        echo "include 'custom.conf'" | sudo -u postgres tee -a /usr/local/pgsql/data/postgresql.conf
        echo "include 'master.conf'" | sudo -u postgres tee -a /usr/local/pgsql/data/postgresql.conf
    fi
fi

if [ 0 -eq 0 ]; then
    echo -e "\nUpgrade postgres 93 to 11"
    if [ "$mode" == 'live' ]; then
        cd ~postgres
        old_bin='/usr/lib/postgresql/9.3/bin'
        old_conf='/etc/postgresql/9.3/main'
        new_bin='/usr/local/pgsql/bin'
        new_conf='/usr/local/pgsql/data'
        sudo -u postgres pg_ctlcluster 9.3 main stop -m fast
        sudo -u postgres "$new_bin/pg_ctl" -D "$new_conf" stop
        sudo -u postgres "$new_bin/pg_upgrade" -b "$old_bin" -d "$old_conf" -B $new_bin -D "$new_conf"
        sudo -u postgres "$new_bin/pg_ctl" -D "$new_conf" start
        # Helper lines with vars filled in 
        # /usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data stop
        # /usr/local/pgsql/bin/pg_upgrade -b /usr/lib/postgresql/9.3/bin -d '/etc/postgresql/9.3/main' -B '/usr/local/pgsql/bin' -D '/usr/local/pgsql/data'
        # example start server: sudo -u postgres /usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data start
        # example see data: /usr/local/pgsql/bin/psql -d encoded
        sudo -u root mv /usr/bin/psql /usr/bin/psql.original93
        sudo -u root ln -s /usr/local/pgsql/bin/psql /usr/bin/psql
    fi
fi

if [ 0 -eq 0 ]; then
    echo -e "\nInstall wal-e for python 3.4"
    echo 'Wait a few minutes, the wal archiving may print out more statements.'
    echo ' this probably does not matter. I suspect they are just hanging console logs.'
    echo ' And this backup is not really needed. since we are keeping the old backup on prod.'
    echo 'then run the install-wale.sh script in command dir'
    echo 'then run the following three commands by hand as postgres user'

    echo -e '\nThe following installation must be done manually as postgres user at the momement'
    echo 'sudo su - postgres'
    echo '$/opt/pg-wal-e/.py343-wal-e/bin/pip install -r /opt/pg-wal-e/wal-e-requirements-py3.txt'
    echo '$git clone https://github.com/wal-e/wal-e.git /opt/pg-wal-e/wal-e'
    echo '$/opt/pg-wal-e/.py343-wal-e/bin/pip install -e /opt/pg-wal-e/wal-e'
    echo '$exit'

    echo -e "\nAfter running these commands rerun this script with waleokay as ubuntu user.'
    echo '$./update-pg93to11.sh live demo waleokay'
    exit 0
fi


exit 9999
