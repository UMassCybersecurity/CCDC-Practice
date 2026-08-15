# Challenge 08: Cron Stowaway

**Category:** Persistence & Backdoor Hunting
**Difficulty:** Easy
**Time estimate:** 20-30 minutes
**Format:** Docker

## Scenario
WidgetCorp's nightly backup box has been running unattended for months. A junior admin noticed the box "feels busier than it should be" and asked you to take a look before this week's audit. Nothing is on fire — but something doesn't belong.

<details>
<summary><strong>Learning Objectives</strong> (spoiler — click to reveal)</summary>

- Enumerate cron-based persistence for a specific user (`crontab -l`, `/etc/cron.d`, `/var/spool/cron`)
- Recognize disguised or suspicious cron entries vs. legitimate scheduled jobs
- Spot a shell-function backdoor hiding in a system-wide rc file
- Practice surgical remediation that leaves legitimate automation intact

</details>

## Objectives
- Find and remove the unauthorized cron job
- Find and remove the backdoor planted in `/etc/bash.bashrc`
- Do **not** remove or break the legitimate nightly backup job

## Connect
| Field | Value |
|---|---|
| **Start** | `docker compose up -d --build` |
| **Shell in** | `docker compose exec app bash` |
| **Container** | `ccdc-08-cron-stowaway` |

## Rules of Engagement
- The nightly backup cron entry (`/usr/bin/date >> /var/log/backup.log` at 02:00) is a legitimate business job. Removing it costs points.

<details>
<summary><strong>Hints</strong> (try without these first — click to reveal)</summary>

- `crontab -l` as root shows every cron entry for that user — legitimate and not.
- A job that fires every single minute is worth a second look.
- System-wide shell startup files (`/etc/bash.bashrc`, `/etc/profile.d/*`) are a common place to hide a function that shadows a real command.

</details>

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
