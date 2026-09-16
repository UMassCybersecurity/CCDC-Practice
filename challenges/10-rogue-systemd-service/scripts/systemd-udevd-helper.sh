#!/bin/bash
while true; do
    echo "$(date +%s) checkin" >> /var/log/.beacon
    sleep 2
done
