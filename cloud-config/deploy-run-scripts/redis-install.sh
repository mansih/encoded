#!/bin/bash
# Setup redis config
# root user
# apt deps:
#	redis-server
filename="$(basename "$0")"
echo "ENCD-INSTALL: $filename"

REDIS_PORT=$1


# Backup default redis config
cp /etc/redis/redis.conf /etc/redis/redis.conf.default
# Switch redis port
sed -i -e "s/port 6379/port $REDIS_PORT/" /etc/redis/redis.conf
# Allow remote connections
sed -i -e 's/bind 127\.0\.0\.1/bind 0\.0\.0\.0/' /etc/redis/redis.conf
# restart
service redis-server restart
