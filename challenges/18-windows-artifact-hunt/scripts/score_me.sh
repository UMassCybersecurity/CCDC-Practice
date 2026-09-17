#!/bin/bash
# Challenge 18 - Windows Artifact Hunt - Scoring Engine
# Run inside the container: docker compose exec app /scripts/score_me.sh

FINDINGS=/root/findings.txt
SCORE=0
MAX_SCORE=3

echo "========================================"
echo " Windows Artifact Hunt Scoring Engine"
echo "========================================"
echo ""

if [ ! -f "$FINDINGS" ]; then
    echo "[X] FAIL: $FINDINGS does not exist. Write your findings there first."
    echo ""
    echo "FINAL SCORE: 0 / $MAX_SCORE"
    exit 1
fi

if grep -qxF "IFEO_TARGET: sethc.exe" "$FINDINGS"; then
    echo "[PASS] IFEO target binary identified. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] IFEO target missing or incorrect (expected: IFEO_TARGET: sethc.exe)"
fi

if grep -qxF 'IFEO_DEBUGGER: C:\Windows\System32\cmd.exe' "$FINDINGS"; then
    echo "[PASS] IFEO debugger value identified. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] IFEO debugger missing or incorrect (expected: IFEO_DEBUGGER: C:\Windows\System32\cmd.exe)"
fi

if grep -qxF 'TASK_NAME: \Microsoft\Windows\SystemHealth\Telemetry' "$FINDINGS"; then
    echo "[PASS] Malicious scheduled task identified. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Scheduled task path missing or incorrect (expected: TASK_NAME: \Microsoft\Windows\SystemHealth\Telemetry)"
fi

echo ""
echo "========================================"
echo " FINAL SCORE: $SCORE / $MAX_SCORE"
echo "========================================"
