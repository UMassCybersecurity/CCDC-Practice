# Challenge 08: The Backup Box

**Category:** Persistence & Backdoor Hunting
**Difficulty:** Easy
**Time estimate:** 20-30 minutes
**Format:** Docker
**Track:** Linux/Docker/SIEM

## Scenario
WidgetCorp's nightly backup box has been running unattended for months. A junior admin noticed the box "feels busier than it should be" and asked you to take a look before this week's audit. Nothing is on fire — but something doesn't belong.

## Objectives
- Find and remove the unauthorized cron job
- There's also a backdoor hiding in a shell startup file somewhere on this box — find and remove it
- Do **not** remove or break the legitimate nightly backup job

## Connect
| Field | Value |
|---|---|
| **Start** | `docker compose up -d --build` |
| **Shell in** | `docker compose exec app bash` |
| **Container** | `ccdc-08-backup-box` |

## Rules of Engagement
- The nightly backup cron entry (`/usr/bin/date >> /var/log/backup.log` at 02:00) is a legitimate business job. Removing it costs points.

## Scoring
Run `docker compose exec app score_me.sh` from the challenge directory on the host.

**3 points total.** Full breakdown is in ANSWER.md.
