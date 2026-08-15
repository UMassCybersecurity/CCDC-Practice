#!/bin/bash
# Challenge 16 - Live Intrusion Detection - Scoring Engine
# Run inside the VM: sudo /vagrant/scripts/score_me.sh

FINDINGS=/root/findings.txt
SCORE=0
MAX_SCORE=4

echo "========================================"
echo " Live Intrusion Detection Scoring Engine"
echo "========================================"
echo ""

# Check 1: rogue systemd unit gone (or at least disabled+stopped)
if ! systemctl is-active --quiet systemd-udevd-helper && ! systemctl is-enabled --quiet systemd-udevd-helper 2>/dev/null; then
    echo "[✓] PASS: Rogue systemd-udevd-helper service is stopped and disabled. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Rogue systemd-udevd-helper service is still active or enabled."
fi

# Check 2: rogue process/port no longer live
if ! pgrep -f "systemd-udevd-helper" >/dev/null && ! ss -tln | grep -q ":4917 "; then
    echo "[✓] PASS: Rogue process is no longer running and port 4917 is closed. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Rogue process or listener on port 4917 is still alive."
fi

# Check 3: findings recorded
if [ -f "$FINDINGS" ] && grep -qx "PROCESS: systemd-udevd-helper" "$FINDINGS" && grep -qx "PORT: 4917" "$FINDINGS"; then
    echo "[✓] PASS: Findings correctly identify the rogue process and port. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: $FINDINGS missing or incorrect (expected PROCESS: systemd-udevd-helper / PORT: 4917)."
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
