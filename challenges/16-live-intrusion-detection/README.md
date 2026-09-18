# Challenge 16: Live Intrusion Detection

**Category:** Log & Traffic Analysis / Detection
**Difficulty:** Medium
**Time estimate:** 40-60 minutes
**Format:** Vagrant (Linux)
**Track:** Linux/Docker/SIEM

## Scenario
`prod-app03` is live and serving traffic right now — and so, apparently, is
something else. A junior analyst noticed the box "feels busy" but couldn't
pin down why before their shift ended. It's still running. Find out what's
live on this box and shut it down.

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

## Scoring
Inside the VM: `sudo /vagrant/scripts/score_me.sh`

**4 points total.** Full breakdown is in ANSWER.md.

> **Expected finding count: 1 live rogue process**
