#!/bin/bash
# Challenge 24 - Multi-Source Log Correlation - Scoring Engine
# Run inside the container: docker compose exec app /scripts/score_me.sh

FINDINGS=/root/findings.txt
SCORE=0
MAX_SCORE=4

echo "========================================"
echo " Multi-Source Log Correlation Scoring Engine"
echo "========================================"
echo ""

if [ ! -f "$FINDINGS" ]; then
    echo "[X] FAIL: $FINDINGS does not exist. Write your findings there first."
    echo ""
    echo "FINAL SCORE: 0 / $MAX_SCORE"
    exit 1
fi

if grep -qx "IP: 203.0.113.44" "$FINDINGS"; then
    echo "[PASS] Attacker IP identified. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Attacker IP missing or incorrect (expected: IP: 203.0.113.44)"
fi

if grep -qx "ENDPOINT: /upload.php" "$FINDINGS"; then
    echo "[PASS] Exploited endpoint identified. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Exploited endpoint missing or incorrect (expected: ENDPOINT: /upload.php)"
fi

if grep -qi "^PERSISTENCE:.*authorized_keys" "$FINDINGS"; then
    echo "[PASS] Persistence mechanism identified. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Persistence mechanism missing or incorrect (expected: PERSISTENCE line mentioning authorized_keys)"
fi

if grep -qx "TIME: 02/Jun/2026:14:03:41 +0000" "$FINDINGS"; then
    echo "[PASS] Initial exploit timestamp identified. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Timestamp missing or incorrect (expected: TIME: 02/Jun/2026:14:03:41 +0000)"
fi

echo ""
echo "========================================"
echo " FINAL SCORE: $SCORE / $MAX_SCORE"
echo "========================================"
