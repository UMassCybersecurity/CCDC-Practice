# Challenge 10: Rogue systemd Service

**Category:** Persistence & Backdoor Hunting
**Difficulty:** Easy
**Time estimate:** 20-30 minutes
**Format:** Docker

## Scenario
WidgetCorp's monitoring box runs one job: a lightweight agent that writes a heartbeat every few seconds. Someone noticed the box's process list looks a little busier than a single heartbeat script should account for.

<details>
<summary><strong>Learning Objectives</strong> (spoiler — click to reveal)</summary>

- Triage a process list for something that doesn't belong (`ps aux`)
- Recognize process-name masquerading as a persistence/evasion technique
- Understand that killing a process isn't remediation if whatever respawns it is still in place
- Remediate without disturbing an unrelated legitimate process

</details>

## Objectives
- Identify the disguised rogue process and stop it for good
- Keep `monitoring-agent` running throughout

## Connect
| Field | Value |
|---|---|
| **Start** | `docker compose up -d --build` |
| **Shell in** | `docker compose exec app bash` |
| **Container** | `ccdc-10-rogue-systemd-service` |

## Rules of Engagement
- `monitoring-agent`'s heartbeat log must keep growing throughout — don't kill it by mistake.

<details>
<summary><strong>Hints</strong> (try without these first — click to reveal)</summary>

- `ps aux` — one of these processes is not what its name claims to be.
- Killing the process alone isn't enough if something keeps bringing it back within a few seconds.
- Check `/opt/` for anything that doesn't belong.

</details>

## Scoring
Run `docker compose exec app score_me.sh` from the challenge directory on the host.

<details>
<summary>Scoring criteria (spoiler — click to reveal)</summary>

| Points | Criteria |
|---|---|
| +1 | `monitoring-agent` heartbeat still active |
| +1 | Rogue beacon process no longer checking in |
| +1 | Disguised persistence script removed from disk (can't respawn) |

> **Expected finding count: 1**

</details>
