# Challenge 12: The Ops Box

**Category:** Persistence & Backdoor Hunting
**Difficulty:** Hard
**Time estimate:** 40-60 minutes
**Format:** Vagrant (Linux)
**Track:** Linux/Docker/SIEM

## Scenario
WidgetCorp's ops box runs a legitimate Apache site and not much else — or so the previous admin thought. An audit is coming up and you've been asked to sweep the box for anything that shouldn't be there before it happens.

## Objectives
- Find and remove all 6 persistence mechanisms
- Keep the Apache web server online throughout
- Document what you found (technique, artifact, how it was remediated)

## Connect
| Field | Value |
|---|---|
| **SSH To** | `vagrant ssh` (or 192.168.56.10) |
| **Username** | `vagrant` |
| **Password** | `vagrant` |

## Rules of Engagement
- Do not stop the Apache web service — it must remain online.
- Do not remove the legitimate `vagrant` account.

## Scoring
Run `sudo /vagrant/scripts/score_me.sh` inside the VM.

**7 points total** — 6 for the persistence mechanisms found and removed, plus 1 for Apache still online. Full breakdown is in ANSWER.md.

> **Expected persistence count: 6**
