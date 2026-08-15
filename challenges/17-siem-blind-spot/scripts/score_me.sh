#!/bin/bash
# Challenge 17 - SIEM Blind Spot - Scoring Engine
# Run inside the VM: sudo /vagrant/scripts/score_me.sh

SCORE=0
MAX_SCORE=4

echo "========================================"
echo " SIEM Blind Spot Scoring Engine"
echo "========================================"
echo ""

# Check 1: rsyslog discard filter for 'mallory' is gone
if ! grep -rq "mallory" /etc/rsyslog.conf /etc/rsyslog.d/ 2>/dev/null; then
    echo "[✓] PASS: rsyslog filter suppressing mallory's log lines is removed. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: rsyslog config still references/suppresses mallory."
fi

# Check 2: rsyslog is still running (didn't just disable logging entirely)
if systemctl is-active --quiet rsyslog; then
    echo "[✓] PASS: rsyslog service is running. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: rsyslog service is not running."
fi

# Check 3: mallory's cron persistence is gone (job removed, or account removed)
if ! id mallory &>/dev/null; then
    echo "[✓] PASS: Rogue mallory account and its persistence are gone. (+1)"
    SCORE=$((SCORE+1))
elif ! crontab -l -u mallory 2>/dev/null | grep -q "mallory_beacon"; then
    echo "[✓] PASS: mallory's cron persistence has been removed. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: mallory's cron persistence is still present."
fi

# Check 4: legit web service still up (business continuity)
if curl -s http://localhost | grep -q "Apache2 Ubuntu Default Page"; then
    echo "[✓] PASS: Apache web server is online and responding. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Web server is down! You broke a business service."
fi

echo ""
echo "========================================"
echo " FINAL SCORE: $SCORE / $MAX_SCORE"
echo "========================================"
