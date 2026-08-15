#!/bin/bash
# Challenge 13 - Log Triage - Scoring Engine
# Run inside the container: docker compose exec app /scripts/score_me.sh

FINDINGS=/root/findings.txt
SCORE=0
MAX_SCORE=3

echo "========================================"
echo " Log Triage Scoring Engine"
echo "========================================"
echo ""

if [ ! -f "$FINDINGS" ]; then
    echo "[X] FAIL: $FINDINGS does not exist. Write your findings there first."
    echo ""
    echo "FINAL SCORE: 0 / $MAX_SCORE"
    exit 1
fi

if grep -qx "IP: 203.0.113.77" "$FINDINGS"; then
    echo "[PASS] Attacker IP identified. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Attacker IP missing or incorrect (expected: IP: 203.0.113.77)"
fi

if grep -qx "USER: dave" "$FINDINGS"; then
    echo "[PASS] Compromised username identified. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Compromised username missing or incorrect (expected: USER: dave)"
fi

if grep -qx "TIME: Mar 14 02:11:03" "$FINDINGS"; then
    echo "[PASS] Timestamp of successful login identified. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Timestamp missing or incorrect (expected: TIME: Mar 14 02:11:03)"
fi

echo ""
echo "========================================"
echo " FINAL SCORE: $SCORE / $MAX_SCORE"
echo "========================================"
