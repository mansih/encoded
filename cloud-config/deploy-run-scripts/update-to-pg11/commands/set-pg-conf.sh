#!/bin/bash
if [ -z $1 ]; then
    echo -e "\t\tFirst arg is mode.  live or test"
    exit 1
fi
mode="$1"
conf_str=
if [ "$2" == 'master' ]; then
    conf_str="$2"
else
    if [ "$2" == 'demo' ]; then
        conf_str="$2"
    else
        echo -e "\t\tSecond arg is conf type. master or demo"
        exit 2
    fi
fi
test_files="$3"
if [ -z $3 ]; then
    test_files="./test-files" 
fi
pg_version='pg93'
if [ "$4" == 'pg11' ]; then
    pg_version="$4"
fi

echo -e "\tSetting posthres conf to include $conf_str"

# Set run vars
pg_conf_path="$test_files/postgresql.conf"
if [ "$mode" == 'live' ]; then
    pg_conf_path='/etc/postgresql/9.3/main/postgresql.conf'
    if [ "$pg_version" == 'pg11' ]; then
        pg_conf_path='/usr/local/pgsql/data/postgresql.conf'
    fi
fi

# Flip demo and master for reversion
custom_conf="include 'custom.conf'"
demo_conf="include 'master.conf'"
master_conf="include 'demo.conf'"
if [ "$conf_str" == 'master' ]; then
    custom_conf="include 'custom.conf'"
    demo_conf="include 'demo.conf'"
    master_conf="include 'master.conf'"
fi

function restart_postgres() {
    same_mode="$1"
    if [ "$same_mode" == 'live' ]; then
        echo -e '\t\tRestarting postgres'
        if [ "$2" == 'pg11' ]; then
            /usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data restart -m fast
        else
            pg_ctlcluster 9.3 main restart -m fast
        fi
        exit 0
    else
        echo -e '\t\tTest: Not restarting postgres'
        exit 0
    fi
    exit 999
}

# Get current last line
last_pgconf_line="$(tail -n 1 $pg_conf_path)"

# Last line Custom
if [ "$last_pgconf_line" == "$custom_conf" ]; then
    echo -e "\t\tAppending $master_conf to $pg_conf_path"
    echo $master_conf >> $pg_conf_path
    restart_postgres $mode $pg_version
    if [ $? -ne 0 ]; then
        exit 3
    fi
    exit 0
fi

# Last line Demo
if [ "$last_pgconf_line" == "$demo_conf" ]; then
    echo -e "\t\tRemoving $demo_conf and Appending $master_conf in $pg_conf_path"
    # GNU
    sed -i '$ d' "$pg_conf_path"
    if [ $? -eq 0 ]; then
        echo -e '\t\tGNU works'
    else
        # MAC
        sed -i '' -e '$ d' "$pg_conf_path"
        if [ $? -eq 0 ]; then
            echo -e '\t\tAbove gnu failed. Trying MAC.'
        else
            echo -e '\t\tCould not cut last line'
            exit 3
        fi
    fi
    echo $master_conf >> $pg_conf_path
    restart_postgres $mode $pg_version
    if [ $? -ne 0 ]; then
        exit 4
    fi
    exit 0
fi

# Last line Master
if [ "$last_pgconf_line" == "$master_conf" ]; then
    echo -e "\t\tNoop. $pg_conf_path already has $master_conf"
    exit 0
fi

exit 9999
