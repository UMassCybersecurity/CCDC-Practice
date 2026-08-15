#!/bin/bash
# Challenge 05 - Container Secrets Leak - Scoring Engine
# Run this from the challenge directory on the HOST: ./scripts/score_me.sh

cd "$(dirname "$0")/.." || exit 1

BASE="http://localhost:8103"
SCORE=0
MAX_SCORE=4

echo "========================================"
echo " WidgetCorp API Scoring Engine v1.0"
echo "========================================"
echo ""

# Check 1: /crash no longer leaks a debug traceback
if curl -s --max-time 5 "$BASE/crash" | grep -qi "Traceback"; then
    echo "[X] FAIL: /crash still leaks a debug traceback."
else
    echo "[✓] PASS: /crash no longer leaks a debug traceback. (+1)"
    SCORE=$((SCORE+1))
fi

# Check 2: /status no longer leaks the API key
if curl -s --max-time 5 "$BASE/status" | grep -q "sk-widgetcorp-prod-4f9a2b7c"; then
    echo "[X] FAIL: /status still leaks the API key."
else
    echo "[✓] PASS: /status no longer leaks the API key. (+1)"
    SCORE=$((SCORE+1))
fi

# Check 3: /files/.env is blocked
CODE=$(curl -s -o /dev/null --max-time 5 -w '%{http_code}' "$BASE/files/.env")
if [[ "$CODE" == "403" || "$CODE" == "404" ]]; then
    echo "[✓] PASS: /files/.env is blocked (got $CODE). (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: /files/.env is still reachable (got $CODE)."
fi

# Check 4: the app still works — main page and the legit static asset
MAIN=$(curl -s -o /dev/null --max-time 5 -w '%{http_code}' "$BASE/")
LOGO=$(curl -s -o /dev/null --max-time 5 -w '%{http_code}' "$BASE/files/logo.txt")
if [[ "$MAIN" == "200" && "$LOGO" == "200" ]]; then
    echo "[✓] PASS: Main page and legit static asset still serve. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Main page or legit static asset broke (/ = $MAIN, /files/logo.txt = $LOGO)."
fi

echo ""
echo "========================================"
echo " FINAL SCORE: $SCORE / $MAX_SCORE"
echo "========================================"

if [ $SCORE -eq $MAX_SCORE ]; then
    echo "Excellent work! Secrets are contained and the API still works."
else
    echo "Keep trying! Review the failed checks and try again."
fi
