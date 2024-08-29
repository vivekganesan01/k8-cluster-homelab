#!/bin/sh

# Start Redis in the background
redis-server /usr/local/etc/redis/redis.conf &

# Start stunnel in the background and log output
stunnel /etc/stunnel/stunnel.conf 2>&1 | tee /var/log/stunnel.log &

# Wait for any process to exit and capture the exit code
exit $?