# Challenge 15: Brute-Force Detector

**Category:** Log & Traffic Analysis / Detection
**Difficulty:** Medium
**Time estimate:** 30-40 minutes
**Format:** Docker

## Scenario
`prod-app03` has a day's worth of SSH auth logs, and somewhere in the noise
is one IP that's clearly brute-forcing a login. You don't get to just read
the answer this time — write a small script that finds it for you, the way a
real detection rule would.

<details>
<summary><strong>Learning Objectives</strong> (spoiler — click to reveal)</summary>

- Build a simple log-based detection script (bash/awk or your language of choice)
- Set a threshold that catches real attacks without flagging normal failed-login noise
- Practice separating signal from noise in a moderately busy log

</details>

## Objectives
- Write a script that scans `/var/log/auth.log` and flags any source IP with
  an unusually high number of failed SSH logins
- Output every flagged IP to `/root/alerts.log`, one per line, with **no
  false positives** from ordinary background noise

## Connect
| Field | Value |
|---|---|
| **Start** | `docker compose up -d --build` |
| **Shell in** | `docker compose exec app bash` |
| **Log location** | `/var/log/auth.log` inside the container |
| **Alerts file** | `/root/alerts.log` inside the container (you create this) |

## Rules of Engagement
- This is a read-only analysis exercise — there is nothing to break, only a log to read and a detector to write.
- `/root/alerts.log` should contain flagged IPs only — one per line, nothing else.

<details>
<summary><strong>Hints</strong> (try without these first — click to reveal)</summary>

- `awk '{print $9}' /var/log/auth.log | sort | uniq -c | sort -rn` gets you a per-IP failure count fast.
- The malicious IP isn't subtle once you count — it's an order of magnitude above the noisiest benign IP.
- Pick a threshold with headroom on both sides rather than tuning it to a single log.

</details>

## Scoring
From the challenge directory on the host: `docker compose exec app /scripts/score_me.sh`

<details>
<summary>Scoring criteria (spoiler — click to reveal)</summary>

| Points | Criteria |
|---|---|
| +1 | Malicious IP flagged in `/root/alerts.log` |
| +1 | No benign IP falsely flagged |
| +1 | `/root/alerts.log` contains exactly one line (no noise/duplicates) |

> **Expected finding count: 1 malicious IP out of 6 total source IPs in the log**

</details>
