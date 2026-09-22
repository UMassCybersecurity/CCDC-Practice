# Challenge 10: The Monitoring Box

**Category:** Persistence & Backdoor Hunting
**Difficulty:** Easy
**Time estimate:** 20-30 minutes
**Format:** Docker
**Track:** Linux/Docker/SIEM

## Scenario
WidgetCorp's monitoring box runs one job: a lightweight agent that writes a heartbeat every few seconds. Someone noticed the box's process list looks a little busier than a single heartbeat script should account for.

## Objectives
- Identify the disguised rogue process and stop it for good
- Keep `monitoring-agent` running throughout

## Connect
| Field | Value |
|---|---|
| **Start** | `docker compose up -d --build` |
| **Shell in** | `docker compose exec app bash` |
| **Container** | `ccdc-10-monitoring-box` |

## Rules of Engagement
- `monitoring-agent`'s heartbeat log must keep growing throughout — don't kill it by mistake.

## Scoring
Run `docker compose exec app score_me.sh` from the challenge directory on the host.

**3 points total.** Full breakdown is in ANSWER.md.
