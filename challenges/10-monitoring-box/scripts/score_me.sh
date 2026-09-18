#!/bin/bash
# Challenge 10 - Rogue systemd Service - Scoring Engine
# Run this inside the container: docker compose exec app score_me.sh

SCORE=0
MAX_SCORE=3

echo "========================================"
echo " Rogue Service Scoring Engine v1.0"
echo "========================================"
echo ""

AGENT_LOG=/var/log/monitoring-agent.log
BEACON_LOG=/var/log/.beacon

before_agent=$(wc -l < "$AGENT_LOG" 2>/dev/null || echo 0)
before_beacon=$(wc -l < "$BEACON_LOG" 2>/dev/null || echo 0)
sleep 4
after_agent=$(wc -l < "$AGENT_LOG" 2>/dev/null || echo 0)
after_beacon=$(wc -l < "$BEACON_LOG" 2>/dev/null || echo 0)

# Check 1: legit monitoring-agent still alive
if [ "$after_agent" -gt "$before_agent" ]; then
    echo "[✓] PASS: monitoring-agent heartbeat is still active. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: monitoring-agent heartbeat has stopped."
fi

# Check 2: rogue beacon process no longer running
if [ "$after_beacon" -eq "$before_beacon" ]; then
    echo "[✓] PASS: Rogue beacon process is no longer active. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Rogue beacon process is still checking in."
fi

# Check 3: persistence artifact removed so it can't respawn
if [ ! -e /opt/.sys/systemd-udevd-helper ]; then
    echo "[✓] PASS: Disguised persistence script has been removed. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Disguised persistence script is still present at /opt/.sys/systemd-udevd-helper."
fi

echo ""
echo "========================================"
echo " FINAL SCORE: $SCORE / $MAX_SCORE"
echo "========================================"

if [ $SCORE -eq $MAX_SCORE ]; then
    echo "Clean. The rogue watcher is gone and monitoring-agent is untouched."
else
    echo "Keep trying! Review the failed checks and try again."
fi
