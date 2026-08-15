#!/bin/bash
# Challenge 09 - Webshell Hunt - Scoring Engine
# Run this from the challenge directory on the HOST: ./scripts/score_me.sh

cd "$(dirname "$0")/.." || exit 1

SCORE=0
MAX_SCORE=3

echo "========================================"
echo " Webshell Hunt Scoring Engine v1.0"
echo "========================================"
echo ""

# Check 1: planted webshell is gone
if ! docker compose exec -T web grep -rlq 'system($_POST' /var/www/html 2>/dev/null; then
    echo "[✓] PASS: No command-execution backdoor found under the web root. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: A command-execution backdoor is still present under the web root."
fi

# Check 2: legit site still up
CODE=$(curl -s -o /dev/null --max-time 5 -w '%{http_code}' http://localhost:8201/)
if [ "$CODE" = "200" ]; then
    echo "[✓] PASS: Company site is still reachable (got $CODE). (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Company site is not reachable (got $CODE)."
fi

# Check 3: legit uploaded file still present
CODE=$(curl -s -o /dev/null --max-time 5 -w '%{http_code}' http://localhost:8201/uploads/welcome.txt)
if [ "$CODE" = "200" ]; then
    echo "[✓] PASS: Legitimate uploaded file still served (got $CODE). (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Legitimate uploaded file is missing (got $CODE)."
fi

echo ""
echo "========================================"
echo " FINAL SCORE: $SCORE / $MAX_SCORE"
echo "========================================"

if [ $SCORE -eq $MAX_SCORE ]; then
    echo "Clean. The webshell is gone and the site is still up."
else
    echo "Keep trying! Review the failed checks and try again."
fi
