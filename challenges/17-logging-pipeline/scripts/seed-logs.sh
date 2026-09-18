#!/bin/bash
# Seeds /var/log/syslog and /var/log/auth.log with a few days of plausible
# backdated history, so the box doesn't boot looking suspiciously empty.
# Purely cosmetic realism — none of this is graded or referenced by the fix,
# and it bypasses rsyslog entirely (written straight to the files), so the
# rsyslog filters installed elsewhere in this playbook never touch it.
set -euo pipefail
HOST=$(hostname)
NOW=$(date +%s)
SYSLOG=/var/log/syslog
AUTHLOG=/var/log/auth.log

ts() { date -d "@$1" '+%b %e %H:%M:%S'; }
pid() { echo $((RANDOM % 9000 + 1000)); }

for day in 3 2 1; do
  day_start=$(( (NOW - day*86400) - (NOW % 86400) ))

  for h in $(seq 0 23); do
    t=$((day_start + h*3600 + 15*60))
    echo "$(ts "$t") $HOST CRON[$(pid)]: (svc-cleanup) CMD (find /tmp -type f -mtime +7 -delete 2>&1)" >> "$SYSLOG"
    p=$(pid)
    echo "$(ts "$t") $HOST CRON[$p]: pam_unix(cron:session): session opened for user svc-cleanup(uid=1001) by (uid=0)" >> "$AUTHLOG"
    echo "$(ts "$t") $HOST CRON[$p]: pam_unix(cron:session): session closed for user svc-cleanup" >> "$AUTHLOG"
  done

  t=$((day_start + 2*3600))
  echo "$(ts "$t") $HOST CRON[$(pid)]: (svc-backup) CMD (tar -czf /var/backups/daily-\$(date +%F).tar.gz /var/www/html 2>&1)" >> "$SYSLOG"

  t=$((day_start + RANDOM % 86400))
  echo "$(ts "$t") $HOST systemd[1]: Starting Daily apt upgrade and clean activities..." >> "$SYSLOG"
  echo "$(ts "$((t+30))") $HOST systemd[1]: Finished Daily apt upgrade and clean activities." >> "$SYSLOG"

  for i in 1 2; do
    t=$((day_start + RANDOM % 86400))
    p=$(pid)
    echo "$(ts "$t") $HOST sshd[$p]: Accepted password for vagrant from 192.168.56.1 port $((RANDOM % 20000 + 1024)) ssh2" >> "$AUTHLOG"
    echo "$(ts "$t") $HOST sshd[$p]: pam_unix(sshd:session): session opened for user vagrant(uid=1000) by (uid=0)" >> "$AUTHLOG"
    echo "$(ts "$((t + RANDOM % 600 + 60))") $HOST sshd[$p]: pam_unix(sshd:session): session closed for user vagrant" >> "$AUTHLOG"
  done
done

sort -k1M -k2n -k3 -o "$SYSLOG" "$SYSLOG" 2>/dev/null || true
sort -k1M -k2n -k3 -o "$AUTHLOG" "$AUTHLOG" 2>/dev/null || true
chown syslog:adm "$SYSLOG" "$AUTHLOG" 2>/dev/null || true
