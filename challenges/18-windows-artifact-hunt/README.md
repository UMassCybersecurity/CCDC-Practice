# Challenge 18: Windows Artifact Hunt

**Category:** Persistence & Backdoor Hunting
**Difficulty:** Easy
**Time estimate:** 20-25 minutes
**Format:** Docker
**Track:** AD/Windows

## Scenario
A Windows file server threw up red flags in monitoring overnight. IR pulled a
static evidence bundle off the box — an Autoruns export, a scheduled task
dump, an IFEO registry export, and a slice of the Security event log —
without touching the live system. You don't get a VM this time: work the
case from the exported artifacts alone, the way a real triage pass starts
before anyone RDPs in.

## Objectives
- Work out how this attacker set themselves up to survive a reboot, using only the evidence provided
- Write your findings to `/root/findings.txt` inside the container, in the format below

## Connect
| Field | Value |
|---|---|
| **Start** | `docker compose up -d --build` |
| **Shell in** | `docker compose exec app bash` |
| **Evidence location** | `/evidence/` inside the container (`autoruns.csv`, `scheduled_tasks.txt`, `ifeo_registry.txt`, `security_events.csv`) |
| **Findings file** | `/root/findings.txt` inside the container (you create this) |

## Rules of Engagement
- This is a read-only analysis exercise — there is nothing to break, only evidence to read.

## Findings format
Write exactly these three lines to `/root/findings.txt` (no extra text):
```
IFEO_TARGET: <name of the binary the attacker attached a debugger to>
IFEO_DEBUGGER: <the Debugger value set on that binary>
TASK_NAME: <full path of the malicious scheduled task>
```

## Scoring
From the challenge directory on the host: `docker compose exec app /scripts/score_me.sh`

**3 points total.** Full breakdown is in ANSWER.md.
