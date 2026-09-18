# Challenge 11: Another Domain Controller Incident

**Category:** Persistence & Backdoor Hunting
**Difficulty:** Hard
**Time estimate:** 40-60 minutes
**Format:** Vagrant (Windows/AD)
**Track:** AD/Windows

## Scenario
corp.local's domain controller was compromised again — a different attacker than the one from Challenge 01, using a different playbook. This one favored quieter, more privileged techniques than last time. Find all five and remove them without breaking the domain.

## Objectives
- Identify and remove all 5 persistence mechanisms
- Keep Active Directory Domain Services and DNS running throughout
- Document what you found (technique, artifact, how it was remediated)

## Connect
| Field | Value |
|---|---|
| **RDP To** | 192.168.56.10 |
| **Username** | CORP\jsmith |
| **Password** | Welcome1! |
| **Domain Admin** | CORP\Administrator / P@ssw0rd! |

## Rules of Engagement
- Do not break AD DS or DNS.
- Do not remove legitimate user accounts (`jsmith`, built-in accounts).

## Scoring
Run `C:\vagrant\scripts\score_me.ps1` inside the VM as Administrator.

**7 points total** — 5 for the persistence mechanisms found and removed, plus 1 each for AD DS and DNS still running. Full breakdown is in ANSWER.md.

> **Expected persistence count: 5**
