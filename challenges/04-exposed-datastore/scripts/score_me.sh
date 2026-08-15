#!/bin/bash
# Challenge 04 - Exposed Datastore - Scoring Engine
# Run this from the challenge directory on the HOST: ./scripts/score_me.sh

cd "$(dirname "$0")/.." || exit 1

SCORE=0
MAX_SCORE=3

echo "========================================"
echo " WidgetCorp Datastore Scoring Engine v1.0"
echo "========================================"
echo ""

# Check 1: Redis is no longer reachable directly from the host
if timeout 3 bash -c "echo -e 'PING\r' | nc -w 2 localhost 8101" 2>/dev/null | grep -qi "PONG"; then
    echo "[X] FAIL: Redis on 8101 is still reachable from the host without auth."
else
    echo "[✓] PASS: Redis is no longer openly reachable on 8101. (+1)"
    SCORE=$((SCORE+1))
fi

# Check 2: Redis requires authentication (checked from inside the compose network)
AUTHCHECK=$(docker compose exec -T redis redis-cli PING 2>&1)
if echo "$AUTHCHECK" | grep -qi "NOAUTH"; then
    echo "[✓] PASS: Redis requires authentication. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Redis does not require authentication (got: $AUTHCHECK)."
fi

# Check 3: The app can still reach Redis and stays healthy
if curl -s --max-time 5 http://localhost:8102/health | grep -q '"status":"ok"'; then
    echo "[✓] PASS: App /health reports a working Redis connection. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: App /health is not reporting a working Redis connection."
fi

echo ""
echo "========================================"
echo " FINAL SCORE: $SCORE / $MAX_SCORE"
echo "========================================"

if [ $SCORE -eq $MAX_SCORE ]; then
    echo "Excellent work! The datastore is locked down and the app still works."
else
    echo "Keep trying! Review the failed checks and try again."
fi
