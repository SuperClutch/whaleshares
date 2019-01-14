#!/bin/bash

echo /tmp/core | tee /proc/sys/kernel/core_pattern
ulimit -c unlimited

mkdir -p /etc/service/whaled
cp /usr/local/bin/whaled-sv-run.sh /etc/service/whaled/run
chmod +x /etc/service/whaled/run
runsv /etc/service/whaled