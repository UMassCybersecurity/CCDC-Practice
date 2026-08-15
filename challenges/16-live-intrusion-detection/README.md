# Challenge 16: Live Intrusion Detection

**Category:** Log & Traffic Analysis / Detection
**Difficulty:** Medium
**Time estimate:** 40-60 minutes
**Format:** Vagrant (Linux)

## Scenario
`prod-app03` is live and serving traffic right now — and so, apparently, is
something else. A junior analyst noticed the box "feels busy" but couldn't
pin down why before their shift ended. It's still running. Find out what's
live on this box and shut it down.

<details>
<summary><strong>Learning Objectives</strong> (spoiler — click to reveal)</summary>

- Enumerate running processes and listening sockets on a live system (`ps`, `ss`)
- Distinguish a disguised persistence mechanism from legitimate system services by behavior, not just name
- Recognize planted red-herring "evidence" and verify findings independently instead of trusting them

</details>

## Objectives
- Find the rogue process running on this box and the port it's using
- Kill it and remove its persistence so it doesn't come back on reboot
- Write your findings to `/root/findings.txt`
- Keep the Apache web service online throughout

## Connect
| Field | Value |
|---|---|
| **Start** | `vagrant up` |
| **Connect** | `vagrant ssh` |
| **IP** | `192.168.56.10` |

## Rules of Engagement
- **DO NOT** stop the Apache2 web service. It must remain online.
- There is a file at `/tmp/.compromise_evidence` — treat anything you find as a lead to verify, not a conclusion to trust.

## Findings format
Write exactly these two lines to `/root/findings.txt` (no extra text):
```
PROCESS: <name of the rogue process/executable>
PORT: <port it was using>
```

<details>
<summary><strong>Hints</strong> (try without these first — click to reveal)</summary>

- `ps aux` and `ss -tlnp` together will show you what's actually running and listening — a legit-sounding name doesn't mean legit.
- `systemctl list-units --type=service` includes both real and rogue services; check what each one's `ExecStart` actually points to.
- A file left behind by "someone else" is not the same thing as evidence you've verified yourself.

</details>

## Scoring
Inside the VM: `sudo /vagrant/scripts/score_me.sh`

<details>
<summary>Scoring criteria (spoiler — click to reveal)</summary>

| Points | Criteria |
|---|---|
| +1 | Rogue systemd service stopped and disabled |
| +1 | Rogue process/port no longer live |
| +1 | Findings correctly identify the process name and port |
| +1 | Apache web server still online |

> **Expected finding count: 1 live rogue process**

</details>
