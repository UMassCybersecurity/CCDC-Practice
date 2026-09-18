# Challenge 13: Log Triage

**Category:** Log & Traffic Analysis / Detection
**Difficulty:** Easy
**Time estimate:** 20 minutes
**Format:** Docker
**Track:** Linux/Docker/SIEM

## Scenario
Overnight monitoring flagged unusual SSH activity on `prod-web01`. Nobody has
investigated yet — the on-call engineer just dumped `/var/log/auth.log` and
went back to bed. Before anyone touches the box, you need to work out exactly
what happened from the log alone: who got in, from where, and when.

## Objectives
- Identify the source IP that successfully compromised an account
- Identify the compromised username
- Identify the timestamp of the first successful login from that IP
- Write your findings to `/root/findings.txt` inside the container

## Connect
| Field | Value |
|---|---|
| **Start** | `docker compose up -d --build` |
| **Shell in** | `docker compose exec app bash` |
| **Log location** | `/var/log/auth.log` inside the container |
| **Findings file** | `/root/findings.txt` inside the container (you create this) |

## Rules of Engagement
- This is a read-only analysis exercise — there is nothing to break, only a log to read.

## Findings format
Write exactly these three lines to `/root/findings.txt` (no extra text):
```
IP: <attacker source IP>
USER: <compromised username>
TIME: <syslog timestamp of the first successful login, e.g. "Mar 14 02:11:03">
```

## Scoring
From the challenge directory on the host: `docker compose exec app /scripts/score_me.sh`

<details>
<summary>Scoring criteria (spoiler — click to reveal)</summary>

| Points | Criteria |
|---|---|
| +1 | Correct attacker IP |
| +1 | Correct compromised username |
| +1 | Correct timestamp of first successful login |

> **Expected finding count: 3**

</details>
