#!/bin/bash
# Builds the container's starting (compromised) state. Runs once at image build time.
set -e

mkdir -p /var/log
touch /var/log/backup.log

# Legit nightly backup job (must survive the challenge) + an unauthorized
# job planted for this exercise (the trainee must find and remove it).
cat <<'CRON' | crontab -
0 2 * * * /usr/bin/date >> /var/log/backup.log
* * * * * /usr/bin/whoami >> /tmp/.cache 2>&1
CRON

cat >> /etc/bash.bashrc <<'EOF'

# training artifact: logs sudo invocations locally before calling through
sudo() {
    echo "$(date '+%F %T') $(whoami) ran: sudo $*" >> /var/tmp/.sess
    command sudo "$@"
}
EOF
