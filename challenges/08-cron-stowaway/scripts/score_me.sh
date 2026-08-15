#!/bin/bash
# Challenge 08 - Cron Stowaway - Scoring Engine
# Run this inside the container: docker compose exec app score_me.sh

SCORE=0
MAX_SCORE=3

echo "========================================"
echo " Cron Stowaway Scoring Engine v1.0"
echo "========================================"
echo ""

# Check 1: Unauthorized per-minute cron job removed
if ! crontab -l 2>/dev/null | grep -qE '^\* \* \* \* \*.*whoami'; then
    echo "[✓] PASS: Unauthorized per-minute cron job has been removed. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Unauthorized per-minute cron job is still present."
fi

# Check 2: Legit nightly backup job untouched
if crontab -l 2>/dev/null | grep -qF '0 2 * * * /usr/bin/date >> /var/log/backup.log'; then
    echo "[✓] PASS: Legit nightly backup cron job is still present. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Legit nightly backup cron job was removed! Business continuity broken."
fi

# Check 3: bashrc sudo-wrapper backdoor removed
if ! grep -q 'training artifact: logs sudo invocations' /etc/bash.bashrc; then
    echo "[✓] PASS: sudo-wrapper backdoor removed from /etc/bash.bashrc. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: sudo-wrapper backdoor still present in /etc/bash.bashrc."
fi

echo ""
echo "========================================"
echo " FINAL SCORE: $SCORE / $MAX_SCORE"
echo "========================================"

if [ $SCORE -eq $MAX_SCORE ]; then
    echo "Clean. No unauthorized persistence left behind."
else
    echo "Keep trying! Review the failed checks and try again."
fi
