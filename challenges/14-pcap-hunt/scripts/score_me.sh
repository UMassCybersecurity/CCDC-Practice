#!/bin/bash
# Challenge 14 - PCAP Hunt - Scoring Engine
# Run inside the container: docker compose exec app /scripts/score_me.sh

FINDINGS=/root/findings.txt
SCORE=0
MAX_SCORE=3

echo "========================================"
echo " PCAP Hunt Scoring Engine"
echo "========================================"
echo ""

if [ ! -f "$FINDINGS" ]; then
    echo "[X] FAIL: $FINDINGS does not exist. Write your findings there first."
    echo ""
    echo "FINAL SCORE: 0 / $MAX_SCORE"
    exit 1
fi

if grep -qx "USER: jdoe" "$FINDINGS"; then
    echo "[PASS] Leaked username identified. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Leaked username missing or incorrect (expected: USER: jdoe)"
fi

if grep -qx "PASS: Fall2025!" "$FINDINGS"; then
    echo "[PASS] Leaked password identified. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Leaked password missing or incorrect (expected: PASS: Fall2025!)"
fi

if grep -qx "BEACON: 203.0.113.50:4444" "$FINDINGS"; then
    echo "[PASS] C2 beacon destination identified. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Beacon destination missing or incorrect (expected: BEACON: 203.0.113.50:4444)"
fi

echo ""
echo "========================================"
echo " FINAL SCORE: $SCORE / $MAX_SCORE"
echo "========================================"
