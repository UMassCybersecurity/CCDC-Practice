#!/bin/bash
# Challenge 03 - TLS Behind Nginx - Scoring Engine
# Run this from the challenge directory on the HOST: ./scripts/score_me.sh

cd "$(dirname "$0")/.." || exit 1

SCORE=0
MAX_SCORE=3

echo "========================================"
echo " WidgetCorp Edge TLS Scoring Engine v1.0"
echo "========================================"
echo ""

# Check 1: HTTPS is actually serving the backend
if curl -sk --max-time 5 https://localhost:8143/ | grep -q "Backend online"; then
    echo "[✓] PASS: HTTPS on 8143 serves the backend. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: HTTPS on 8143 is not serving the backend."
fi

# Check 2: Plain HTTP redirects to HTTPS
CODE=$(curl -s -o /dev/null --max-time 5 -w '%{http_code}' http://localhost:8100/)
if [[ "$CODE" =~ ^3 ]]; then
    echo "[✓] PASS: HTTP on 8100 redirects (got $CODE). (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: HTTP on 8100 did not redirect (got $CODE)."
fi

# Check 3: ssl_protocols restricted to TLSv1.2/TLSv1.3 in the live config
if docker compose exec -T edge grep -q 'ssl_protocols TLSv1.2 TLSv1.3;' /etc/nginx/conf.d/default.conf 2>/dev/null; then
    echo "[✓] PASS: ssl_protocols restricted to TLSv1.2/TLSv1.3. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: ssl_protocols not restricted to TLSv1.2/TLSv1.3 in the edge config."
fi

echo ""
echo "========================================"
echo " FINAL SCORE: $SCORE / $MAX_SCORE"
echo "========================================"

if [ $SCORE -eq $MAX_SCORE ]; then
    echo "Excellent work! TLS is properly terminated at the edge."
else
    echo "Keep trying! Review the failed checks and try again."
fi
