#!/bin/bash
# Challenge 12 - Linux Persistence Hunt - Scoring Engine
# Run this inside the VM using: sudo /vagrant/scripts/score_me.sh

SCORE=0
MAX_SCORE=7

echo "========================================"
echo " Linux Persistence Hunt Scoring Engine v1.0"
echo "========================================"
echo ""

# Check 1: unauthorized root cron job removed
if ! crontab -l -u root 2>/dev/null | grep -q '\.svc-cache'; then
    echo "[✓] PASS: Unauthorized root cron job has been removed. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Unauthorized root cron job is still present."
fi

# Check 2: rogue systemd service removed/disabled
if ! systemctl is-active --quiet systemd-networkd-helper.service 2>/dev/null && \
   ! systemctl list-unit-files 2>/dev/null | grep -q systemd-networkd-helper; then
    echo "[✓] PASS: Rogue systemd-networkd-helper service is gone. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Rogue systemd-networkd-helper service is still active or installed."
fi

# Check 3: SSH authorized_keys backdoor removed
if ! grep -q 'svc-maint@corp' /home/vagrant/.ssh/authorized_keys 2>/dev/null; then
    echo "[✓] PASS: Unauthorized SSH key removed from vagrant's authorized_keys. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Unauthorized SSH key is still in vagrant's authorized_keys."
fi

# Check 4: self-healing rogue user neutralized (account gone AND self-heal script gone)
if ! id svc-tools &>/dev/null && [ ! -f /etc/profile.d/99-cache-check.sh ]; then
    echo "[✓] PASS: Backdoor account and self-healing script both removed. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Backdoor account and/or its self-healing script is still present."
fi

# Check 5: SUID-root shell backdoor removed
if [ ! -e /usr/local/bin/.sysbash ] || [ -z "$(find /usr/local/bin/.sysbash -perm -4000 2>/dev/null)" ]; then
    echo "[✓] PASS: SUID-root shell backdoor removed. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: SUID-root shell backdoor is still present at /usr/local/bin/.sysbash."
fi

# Check 6: rogue NOPASSWD sudoers entry removed
if [ ! -f /etc/sudoers.d/90-reports ]; then
    echo "[✓] PASS: Unauthorized NOPASSWD sudoers entry removed. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Unauthorized NOPASSWD sudoers entry is still present."
fi

# Check 7: legit web service still online
if curl -s http://localhost | grep -q "Apache2 Ubuntu Default Page"; then
    echo "[✓] PASS: Apache Web Server is online and responding. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Web Server is down! You broke a business service."
fi

echo ""
echo "========================================"
echo " FINAL SCORE: $SCORE / $MAX_SCORE"
echo "========================================"

if [ $SCORE -eq $MAX_SCORE ]; then
    echo "Clean. All 6 persistence mechanisms removed, business service intact."
else
    echo "Keep trying! Review the failed checks and try again."
fi
