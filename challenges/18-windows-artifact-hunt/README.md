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

<details>
<summary><strong>Learning Objectives</strong> (spoiler — click to reveal)</summary>

- Read a Sysinternals Autoruns export and separate legitimate startup entries from a masquerading one
- Recognize the classic sticky-keys (`sethc.exe`) Image File Execution Options debugger backdoor in a registry export
- Spot a disguised scheduled task using an encoded PowerShell payload
- Correlate a Security event log slice with the persistence mechanisms it's showing exploitation of

</details>

## Objectives
- Identify the binary targeted by the malicious IFEO `Debugger` value
- Identify the exact `Debugger` value the attacker set
- Identify the full path of the malicious scheduled task
- Write your findings to `/root/findings.txt` inside the container

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

<details>
<summary><strong>Hints</strong> (try without these first — click to reveal)</summary>

- `autoruns.csv` has one entry worth a second look, but it isn't what's graded here — treat it as corroborating evidence, not the answer.
- IFEO `Debugger` values are meant for actual debuggers, not `cmd.exe` — any binary you attach a debugger to via this key never runs; the debugger runs instead.
- In `scheduled_tasks.txt`, compare each task's `Author` field and look for one that runs a lot more often than a normal maintenance task would.
- `security_events.csv` around `09:41` ties the registry key to something that actually happened.

</details>

## Scoring
From the challenge directory on the host: `docker compose exec app /scripts/score_me.sh`

<details>
<summary>Scoring criteria (spoiler — click to reveal)</summary>

| Points | Criteria |
|---|---|
| +1 | Correct IFEO target binary |
| +1 | Correct IFEO debugger value |
| +1 | Correct malicious scheduled task path |

> **Expected finding count: 3**

</details>
