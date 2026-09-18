# Challenge 19: Standalone Windows Hardening

**Category:** Host Hardening / Misconfiguration Audit
**Difficulty:** Easy-Medium
**Time estimate:** 25-35 minutes
**Format:** Vagrant (Windows)
**Track:** AD/Windows

## Scenario
A standalone Windows server was stood up quickly for a project and never got a proper hardening pass. Nothing has been compromised (yet) — this is a proactive audit. Find the local misconfigurations before someone else does.

## Objectives
- Find and remediate all 5 local hardening issues
- Do not break the box's ability to accept RDP connections

## Connect
| Field | Value |
|---|---|
| **Start** | `vagrant up` (~2-3 min once the base box is built) |
| **RDP To** | 192.168.56.10 (or `vagrant rdp`) |
| **Username** | vagrant |
| **Password** | vagrant |

## Rules of Engagement
- Do not disable RDP entirely — you still need to get back in.
- Fix the misconfigurations in place; you don't need to reinstall or reimage anything.

## Scoring
Run `C:\vagrant\scripts\score_me.ps1` inside the VM as Administrator.

**5 points total.** Full breakdown is in ANSWER.md.

> **Expected finding count: 5**
