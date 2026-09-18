#!/bin/bash
# Challenge 06 - File Permissions Audit - Scoring Engine
# Run this inside the VM using: sudo /vagrant/scripts/score_me.sh

SCORE=0
MAX_SCORE=4

echo "========================================"
echo " WidgetCorp Fileshare Audit Scoring Engine v1.0"
echo "========================================"
echo ""

# Check 1: /srv/fileshare is no longer world-writable
if [ -d /srv/fileshare ] && [ -z "$(find /srv/fileshare -perm -002)" ]; then
    echo "[✓] PASS: /srv/fileshare (and its contents) are no longer world-writable. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: /srv/fileshare or a file inside it is still world-writable."
fi

# Check 2: SUID backdoor removed or defused
if [ ! -e /usr/local/bin/.syshelper ] || [ ! -u /usr/local/bin/.syshelper ]; then
    echo "[✓] PASS: The .syshelper SUID backdoor is gone or de-fanged. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: /usr/local/bin/.syshelper still exists with the SUID bit set."
fi

# Check 3: intern's NOPASSWD sudo backdoor removed
if ! grep -rq "intern" /etc/sudoers.d/ 2>/dev/null && ! grep -q "^intern" /etc/sudoers 2>/dev/null; then
    echo "[✓] PASS: intern's passwordless sudo grant has been removed. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: intern still has a sudoers entry."
fi

# Check 4: Business continuity — Apache is still up
if curl -s http://localhost | grep -q "Apache2 Ubuntu Default Page"; then
    echo "[✓] PASS: Apache is still online. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Apache is down! You broke a business service."
fi

echo ""
echo "========================================"
echo " FINAL SCORE: $SCORE / $MAX_SCORE"
echo "========================================"

if [ $SCORE -eq $MAX_SCORE ]; then
    echo "Excellent work! The fileshare is locked down and the site is still up."
else
    echo "Keep trying! Review the failed checks and try again."
fi
