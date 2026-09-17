#!/bin/bash
# Challenge 25 - Container Escape Chain - Scoring Engine
# Run this from the challenge directory on the HOST: ./scripts/score_me.sh

cd "$(dirname "$0")/.." || exit 1

SCORE=0
MAX_SCORE=3

echo "========================================"
echo " Container Escape Chain Scoring Engine"
echo "========================================"
echo ""

# Check 1: app no longer has Docker control-plane access wired in
DOCKER_HOST_VAL=$(docker compose exec -T app printenv DOCKER_HOST 2>/dev/null)
if [ -z "$DOCKER_HOST_VAL" ]; then
    echo "[PASS] app no longer has DOCKER_HOST wired to the dind daemon. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] app still has DOCKER_HOST=$DOCKER_HOST_VAL — it can still control the Docker daemon."
fi

# Check 2: the rogue backdoor-c2 container has been removed from the dind daemon
if docker compose exec -T dind docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "backdoor-c2"; then
    echo "[FAIL] backdoor-c2 is still running on the dind daemon."
else
    echo "[PASS] backdoor-c2 has been removed from the dind daemon. (+1)"
    SCORE=$((SCORE+1))
fi

# Check 3: legitimate app functionality still works
if curl -s --max-time 5 http://localhost:8202/health | grep -q '"status":"ok"'; then
    echo "[PASS] app /health still responds correctly. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] app /health is not responding correctly."
fi

echo ""
echo "========================================"
echo " FINAL SCORE: $SCORE / $MAX_SCORE"
echo "========================================"

if [ $SCORE -eq $MAX_SCORE ]; then
    echo "Excellent work! The docker control-plane exposure is closed and the app still works."
else
    echo "Keep trying! Review the failed checks and try again."
fi
