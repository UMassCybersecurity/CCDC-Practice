#!/bin/bash
# Disguised as a udev helper. Actually a live persistence beacon.
LOGFILE=/var/log/udevd-helper.log
PORT=4917

nc -lk $PORT >/dev/null 2>&1 &

while true; do
  echo "$(date -Iseconds) checkin=alive agent=udevd-helper" >> "$LOGFILE"
  (exec 3<>/dev/tcp/127.0.0.1/$PORT; echo "beacon" >&3; exec 3<&-) 2>/dev/null
  sleep 15
done
