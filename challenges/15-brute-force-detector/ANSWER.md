# Challenge 15 Answer Key — Brute-Force Detector

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's planted
`auth.log` is generated deterministically by `scripts/generate_log.py`
(committed for reproducibility). It contains failed-login noise from five
benign IPs (2-6 failures each, scattered across the day) plus one malicious
IP, `198.51.100.99`, that throws 22 failed passwords at `admin` in under five
minutes — an obvious brute-force burst once you count per-IP failures.

## Step-by-step fix
1. `docker compose exec app bash`
2. Count failed attempts per source IP:
   ```bash
   grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn
   ```
   This prints `198.51.100.99` with 22 failures, next highest is `192.0.2.5`
   with 6 — a clean gap to threshold on.
3. Write a one-line detector and run it:
   ```bash
   grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' \
     | sort | uniq -c | awk '$1 > 10 {print $2}' > /root/alerts.log
   ```
4. Confirm `/root/alerts.log` contains exactly `198.51.100.99`.

## Validation
Ran `docker compose up -d --build` fresh, confirmed `score_me.sh` reports
`0 / 3` with no `alerts.log` present, then ran the detector one-liner above
inside the container and confirmed `score_me.sh` reports `3 / 3`. Torn down
with `docker compose down -v` afterward.
