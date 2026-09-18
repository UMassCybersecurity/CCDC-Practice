# Challenge 23: SIEM Alert Triage

**Category:** SIEM / Alert Triage
**Difficulty:** Medium
**Time estimate:** 30-40 minutes
**Format:** Docker
**Track:** Linux/Docker/SIEM

## Scenario
Your Wazuh manager logged a full day of alerts from `web01` and a handful of
other agents to its usual `alerts.json`. Most of it is tuning noise —
scanners that never get in, routine software updates, normal VPN logins.
Somewhere in there, though, one external host ran a real attack chain from
initial recon all the way to persistence. Your job is to separate the signal
from the noise and reconstruct what actually happened.

## Objectives
- Identify every alert ID that is part of the real intrusion (not background noise)
- Identify the technique that gave the attacker initial access
- Write your findings to `/root/findings.txt` inside the container

## Connect
| Field | Value |
|---|---|
| **Start** | `docker compose up -d --build` |
| **Shell in** | `docker compose exec app bash` |
| **Alert data** | `/var/ossec/logs/alerts/alerts.json` inside the container (the real Wazuh manager alert log path) |
| **Findings file** | `/root/findings.txt` inside the container (you create this) |

## Rules of Engagement
- This is a read-only analysis exercise — there is nothing to break, only alerts to triage.

## Findings format
Write exactly these two lines to `/root/findings.txt` (no extra text):
```
TRUE_POSITIVES: <comma-separated alert IDs, sorted ascending, no spaces>
ROOT_CAUSE: <short phrase naming the initial-access technique>
```

## Scoring
From the challenge directory on the host: `docker compose exec app /scripts/score_me.sh`

<details>
<summary>Scoring criteria (spoiler — click to reveal)</summary>

| Points | Criteria |
|---|---|
| +1 | Every true-positive alert ID in the chain identified, no noise IDs included |
| +1 | Correct root-cause technique named |

> **Expected finding count: 5 alert IDs forming one intrusion, out of 242 total alerts**

</details>
