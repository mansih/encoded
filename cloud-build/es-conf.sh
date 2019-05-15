#!/bin/bash
# Setup elastic search config
# root user
# apt deps:
# 	java
#	elasticsearch with apt_source and key

# Set available java memory
MEMGIGS=$(awk '/MemTotal/{printf "%%.0f", $2 / 1024**2}' /proc/meminfo)
if [ "$MEMGIGS" -gt 32 ]
then
   echo "-Xms8g" >> /etc/elasticsearch/jvm.options
   echo "-Xmx8g" >> /etc/elasticsearch/jvm.options
elif [ "$MEMGIGS" -gt 12 ]
then
   echo "-Xms4g" >> /etc/elasticsearch/jvm.options
   echo "-Xmx4g" >> /etc/elasticsearch/jvm.options
else
   echo "-Xms2g" >> /etc/elasticsearch/jvm.options
   echo "-Xmx2g" >> /etc/elasticsearch/jvm.options
   sysctl "vm.swappiness=1"
   swapon /swapfile
fi
# not sure
update-rc.d elasticsearch defaults
# restart
service elasticsearch restart
