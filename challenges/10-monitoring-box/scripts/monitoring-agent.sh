#!/bin/bash
# Legitimate business process — must keep running.
while true; do
    echo "$(date '+%F %T') heartbeat" >> /var/log/monitoring-agent.log
    sleep 2
done
