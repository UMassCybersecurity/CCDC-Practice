#!/bin/bash
# Challenge 07 - Web App Config Hardening - Scoring Engine
# Run this inside the VM using: sudo /vagrant/scripts/score_me.sh

SCORE=0
MAX_SCORE=4

echo "========================================"
echo " WidgetCorp App Hardening Scoring Engine v1.0"
echo "========================================"
echo ""

# Check 1: widgetapp no longer runs as root
RUNAS=$(ps -eo user,cmd | grep '[a]pp.py' | awk '{print $1}' | head -1)
if [ -n "$RUNAS" ] && [ "$RUNAS" != "root" ]; then
    echo "[✓] PASS: widgetapp is running as '$RUNAS', not root. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: widgetapp is still running as root (or not running at all)."
fi

# Check 2: default admin credential no longer works
RESP=$(curl -s -X POST -d "username=admin&password=admin123" http://localhost/login)
if echo "$RESP" | grep -q '"status":"ok"'; then
    echo "[X] FAIL: default admin/admin123 credential still works."
else
    echo "[✓] PASS: default admin/admin123 credential no longer works. (+1)"
    SCORE=$((SCORE+1))
fi

# Check 3: directory listing disabled
if curl -s http://localhost/app/ | grep -qi "Index of"; then
    echo "[X] FAIL: /app/ still serves a directory listing."
else
    echo "[✓] PASS: /app/ no longer serves a directory listing. (+1)"
    SCORE=$((SCORE+1))
fi

# Check 4: main page still works
if curl -s http://localhost/ | grep -q "WidgetCorp App Online"; then
    echo "[✓] PASS: Main app page is still online. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Main app page is down! You broke a business service."
fi

echo ""
echo "========================================"
echo " FINAL SCORE: $SCORE / $MAX_SCORE"
echo "========================================"

if [ $SCORE -eq $MAX_SCORE ]; then
    echo "Excellent work! The app is hardened and still serving."
else
    echo "Keep trying! Review the failed checks and try again."
fi
