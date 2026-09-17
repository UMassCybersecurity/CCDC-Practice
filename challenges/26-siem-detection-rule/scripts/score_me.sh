#!/bin/bash
# Challenge 26 - SIEM Detection Rule - Scoring Engine
# Run inside the container: docker compose exec app /scripts/score_me.sh

ALERTS=/root/alerts.log
SCORE=0
MAX_SCORE=3

echo "========================================"
echo " SIEM Detection Rule Scoring Engine"
echo "========================================"
echo ""

if [ ! -f "$ALERTS" ]; then
    echo "[X] FAIL: $ALERTS does not exist. Write your detector's output there."
    echo ""
    echo "FINAL SCORE: 0 / $MAX_SCORE"
    exit 1
fi

if grep -qx "45.33.12.201:svc-deploy" "$ALERTS"; then
    echo "[PASS] Anomalous login 45.33.12.201:svc-deploy flagged. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Expected line '45.33.12.201:svc-deploy' not found in $ALERTS"
fi

BENIGN="10.0.4.15:jsmith 10.0.4.22:mgarcia 203.0.113.50:twong 198.51.100.9 192.0.2.77"
FALSE_POSITIVE=0
for entry in $BENIGN; do
    if grep -q "$entry" "$ALERTS"; then
        FALSE_POSITIVE=1
        echo "    (false positive: $entry should not have been flagged)"
    fi
done
if [ "$FALSE_POSITIVE" -eq 0 ]; then
    echo "[PASS] No benign logins falsely flagged. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] One or more benign logins were falsely flagged."
fi

LINES=$(grep -vc '^\s*$' "$ALERTS")
if [ "$LINES" -eq 1 ]; then
    echo "[PASS] Alerts file contains exactly one flagged login. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Expected exactly 1 line in $ALERTS, found $LINES."
fi

echo ""
echo "========================================"
echo " FINAL SCORE: $SCORE / $MAX_SCORE"
echo "========================================"
