#!/bin/bash
# Challenge 15 - Brute-Force Detector - Scoring Engine
# Run inside the container: docker compose exec app /scripts/score_me.sh

ALERTS=/root/alerts.log
SCORE=0
MAX_SCORE=3

echo "========================================"
echo " Brute-Force Detector Scoring Engine"
echo "========================================"
echo ""

if [ ! -f "$ALERTS" ]; then
    echo "[X] FAIL: $ALERTS does not exist. Write your detector's output there."
    echo ""
    echo "FINAL SCORE: 0 / $MAX_SCORE"
    exit 1
fi

if grep -qx "198.51.100.99" "$ALERTS"; then
    echo "[PASS] Malicious IP 198.51.100.99 flagged. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Malicious IP 198.51.100.99 not flagged in $ALERTS"
fi

BENIGN="203.0.113.10 203.0.113.11 192.0.2.5 192.0.2.6 192.0.2.7"
FALSE_POSITIVE=0
for ip in $BENIGN; do
    if grep -qx "$ip" "$ALERTS"; then
        FALSE_POSITIVE=1
        echo "    (false positive: $ip should not have been flagged)"
    fi
done
if [ "$FALSE_POSITIVE" -eq 0 ]; then
    echo "[PASS] No benign IPs falsely flagged. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] One or more benign IPs were falsely flagged."
fi

LINES=$(grep -vc '^\s*$' "$ALERTS")
if [ "$LINES" -eq 1 ]; then
    echo "[PASS] Alerts file contains exactly one flagged IP. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Expected exactly 1 line in $ALERTS, found $LINES."
fi

echo ""
echo "========================================"
echo " FINAL SCORE: $SCORE / $MAX_SCORE"
echo "========================================"
