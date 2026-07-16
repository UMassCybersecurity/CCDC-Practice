#!/bin/bash

# CCDC Beginner Lab 1 - Scoring Engine
# Run this inside the VM using: sudo /vagrant/score_me.sh

SCORE=0
MAX_SCORE=5

echo "========================================"
echo " WidgetCorp Audit Scoring Engine v1.0"
echo "========================================"
echo ""

# Check 1: Is the Firewall Active?
if sudo ufw status | grep -q "Status: active"; then
    echo "[✓] PASS: UFW Firewall is active. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: UFW Firewall is disabled or not configured."
fi

# Check 2: Is the FTP service stopped or blocked?
if ! systemctl is-active --quiet vsftpd; then
    echo "[✓] PASS: Vulnerable FTP service is stopped. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Vulnerable FTP service is still running."
fi

# Check 3: Is the Web Server still online? (Business Inject)
if curl -s http://localhost | grep -q "Apache2 Ubuntu Default Page"; then
    echo "[✓] PASS: Apache Web Server is online and responding. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Web Server is down! You broke a business service."
fi

# Check 4: Has the backdoor user been removed or locked?
if ! id "backupadmin" &>/dev/null; then
    echo "[✓] PASS: Backdoor account 'backupadmin' has been removed. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: Unauthorized account 'backupadmin' still exists on the system."
fi

# Check 5: Is Root Login disabled in SSH?
if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
    echo "[✓] PASS: SSH Root login is disabled. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[X] FAIL: SSH allows root logins. Check your sshd_config."
fi

echo ""
echo "========================================"
echo " FINAL SCORE: $SCORE / $MAX_SCORE"
echo "========================================"

if [ $SCORE -eq $MAX_SCORE ]; then
    echo "Excellent work! The server is secured and ready for production."
else
    echo "Keep trying! Review the failed checks and try again."
fi