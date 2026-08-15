#!/bin/bash
# training artifact: disguised persistence process. Copied into the image
# under the plausible-looking name "systemd-udevd-helper" (no .sh) so it
# blends into `ps aux` output. Loops writing local check-in lines — no real
# network calls are made.
while true; do
    echo "$(date +%s) checkin" >> /var/log/.beacon
    sleep 2
done
