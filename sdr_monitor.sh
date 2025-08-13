#!/bin/bash
#
# sdr_monitor.sh
# 433_sniff monitor script
# can be placed anywhere in the home directory
# ideally in its own folder or hidden .folder
# Written 2023-2025 Kelli McMillan -- kelli@cativerse.com
# This ideally should be called by a cron job with root privileges every minute or so
# Usually this is accomplised by running sudo crontab -e
# Be careful with processes running with root priviliges.
# Always change the default password on your Pi/device and restrict logins to ssh key only if possible
#
threshold=20 #CPU %usage threshold. If CPU time drops below this percentage, kill and restart the process
echo "threshold=$threshold"
cpu=$(ps aux | grep -a 'rtl_433' | grep -v 'grep' | grep -v 'exec' | awk '{print $3}')
pid=$(ps aux | grep -a 'rtl_433' | grep -v 'grep' | grep -v 'exec' | awk '{print $2}')
start=$(ps aux | grep -a 'rtl_433' | grep -v 'grep' | grep -v 'exec' | awk '{print $9}')
cputime=$(ps aux | grep -a 'rtl_433' | grep -v 'grep' | grep -v 'exec' | awk '{print $10}')
if [[ "$cpu" < "$threshold" ]]
then
        echo "restarting rtl433-sniff service"
        systemctl restart rtl433-sniff.service
else
        echo "rtl433-sniff daemon OK -> cpu: $cpu%  pid: $pid  started: $start  cputime: $cputime"
fi
