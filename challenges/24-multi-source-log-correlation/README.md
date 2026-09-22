# Challenge 24: Multi-Source Log Correlation

**Category:** Log & Traffic Analysis / Detection
**Difficulty:** Hard
**Time estimate:** 45-60 minutes
**Format:** Docker
**Track:** Linux/Docker/SIEM

## Scenario
`prod-web03` runs a small storefront app behind nginx. Three independent logs
came out of last week's IR data pull — `nginx_access.log`, the app's own
`app.log`, and `auth.log` — and none of them tell the whole story by itself.
The attack only becomes obvious once you line the three up by timestamp and
IP and read them together.

## Objectives
- Identify the attacker's source IP
- Identify the vulnerable endpoint that was exploited
- Identify the persistence mechanism established after the exploit
- Identify the timestamp of the initial exploit request
- Write your findings to `/root/findings.txt` inside the container

## Connect
| Field | Value |
|---|---|
| **Start** | `docker compose up -d --build` |
| **Shell in** | `docker compose exec app bash` |
| **Log locations** | `/var/log/nginx_access.log`, `/var/log/app.log`, `/var/log/auth.log` inside the container |
| **Findings file** | `/root/findings.txt` inside the container (you create this) |

## Rules of Engagement
- This is a read-only analysis exercise — there is nothing to break, only logs to read.

## Findings format
Write exactly these four lines to `/root/findings.txt` (no extra text):
```
IP: <attacker source IP>
ENDPOINT: <the exploited path>
PERSISTENCE: <short description of the persistence mechanism>
TIME: <nginx-format timestamp of the initial exploit request>
```

## Scoring
From the challenge directory on the host: `docker compose exec app /scripts/score_me.sh`

**4 points total.** Full breakdown is in ANSWER.md.
