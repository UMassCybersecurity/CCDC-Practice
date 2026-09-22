# Challenge 26: SIEM Detection Rule

**Category:** Log & Traffic Analysis / Detection
**Difficulty:** Easy-Medium
**Time estimate:** 25-35 minutes
**Format:** Docker
**Track:** Linux/Docker/SIEM

## Scenario
`prod-app07` has a day's worth of SSH auth logs. There's no brute-force burst
in here this time — the attacker didn't guess a password, they already had
one. Somewhere in the noise is a single successful login that doesn't belong.
You don't get to just read the answer: write a small detection rule that
finds it for you, the way a real SIEM correlation rule would.

## Objectives
- Write a script that scans `/var/log/auth.log` and flags any **successful**
  SSH login from a source IP that never appears anywhere else in the log,
  occurring outside normal business hours (08:00-18:00)
- Output the flagged event to `/root/alerts.log` as a single line, in the
  form `<ip>:<username>` — **no false positives**, and nothing else in the file

## Connect
| Field | Value |
|---|---|
| **Start** | `docker compose up -d --build` |
| **Shell in** | `docker compose exec app bash` |
| **Log location** | `/var/log/auth.log` inside the container |
| **Alerts file** | `/root/alerts.log` inside the container (you create this) |

## Rules of Engagement
- This is a read-only analysis exercise — there is nothing to break, only a log to read and a detector to write.
- `/root/alerts.log` should contain the one flagged line only — no header, no extra output.

## Scoring
From the challenge directory on the host: `docker compose exec app /scripts/score_me.sh`

**3 points total.** Full breakdown is in ANSWER.md.
