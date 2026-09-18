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
- Find and remove the backdoor planted in `/etc/bash.bashrc`
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

<details>
<summary>Scoring criteria (spoiler — click to reveal)</summary>

| Points | Criteria |
|---|---|
| +1 | Unauthorized per-minute cron job removed |
| +1 | Legitimate nightly backup cron job still present |
| +1 | `sudo`-wrapping backdoor removed from `/etc/bash.bashrc` |

> **Expected finding count: 2**

</details>
