#!/bin/bash
# Challenge 23 - SIEM Alert Triage - Scoring Engine
# Run inside the container: docker compose exec app /scripts/score_me.sh

FINDINGS=/root/findings.txt
SCORE=0
MAX_SCORE=2

echo "========================================"
echo " SIEM Alert Triage Scoring Engine"
echo "========================================"
echo ""

if [ ! -f "$FINDINGS" ]; then
    echo "[X] FAIL: $FINDINGS does not exist. Write your findings there first."
    echo ""
    echo "FINAL SCORE: 0 / $MAX_SCORE"
    exit 1
fi

if grep -qx "TRUE_POSITIVES: 1042,1047,1051,1053,1058" "$FINDINGS"; then
    echo "[PASS] True-positive alert chain correctly identified. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] TRUE_POSITIVES missing or incorrect (expected: TRUE_POSITIVES: 1042,1047,1051,1053,1058)"
fi

if grep -qi "ROOT_CAUSE:.*sql injection" "$FINDINGS"; then
    echo "[PASS] Root-cause technique identified. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] ROOT_CAUSE missing or incorrect (expected something naming SQL injection)"
fi

echo ""
echo "========================================"
echo " FINAL SCORE: $SCORE / $MAX_SCORE"
echo "========================================"
