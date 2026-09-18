# Challenge 17: The Logging Pipeline

**Category:** Log & Traffic Analysis / Detection
**Difficulty:** Medium
**Time estimate:** 40-60 minutes
**Format:** Vagrant (Linux)
**Track:** Linux/Docker/SIEM

## Scenario
`prod-app04`'s logs look clean — suspiciously clean. Someone tampered with
the logging pipeline before you got here, and whatever they were hiding is
still running. You need to restore visibility first, then use it to find
what's actually going on.

## Objectives
- Find and remove whatever is suppressing log visibility, and get logging working normally again
- Find and remove the persistence mechanism that suppression was hiding
- Keep the Apache web service online throughout

## Connect
| Field | Value |
|---|---|
| **Start** | `vagrant up` |
| **Connect** | `vagrant ssh` |
| **IP** | `192.168.56.10` |

## Rules of Engagement
- **DO NOT** stop the Apache2 web service. It must remain online.
- **DO NOT** just disable rsyslog entirely to "fix" the blind spot — that trades one blind spot for a bigger one. Fix the actual filter.

## Scoring
Inside the VM: `sudo /vagrant/scripts/score_me.sh`

**4 points total.** Full breakdown is in ANSWER.md.

> **Expected finding count: 1 suppressed log source + 1 hidden persistence mechanism**
