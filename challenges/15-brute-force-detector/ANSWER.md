# Challenge 15 Answer Key — Brute-Force Detector

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## Learning Objectives
- Build a simple log-based detection script (bash/awk or your language of choice)
- Set a threshold that catches real attacks without flagging normal failed-login noise
- Practice separating signal from noise in a moderately busy log

## Hints
- `awk '{print $9}' /var/log/auth.log | sort | uniq -c | sort -rn` gets you a per-IP failure count fast.
- The malicious IP isn't subtle once you count — it's an order of magnitude above the noisiest benign IP.
- Pick a threshold with headroom on both sides rather than tuning it to a single log.

## Scoring breakdown
| Points | Criteria |
|---|---|
| +1 | Malicious IP flagged in `/root/alerts.log` |
| +1 | No benign IP falsely flagged |
| +1 | `/root/alerts.log` contains exactly one line (no noise/duplicates) |

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
