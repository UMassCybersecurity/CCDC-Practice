# Challenge 01: Domain Controller Incident

**Category:** Persistence & Backdoor Hunting
**Difficulty:** Medium
**Time estimate:** 30-60 minutes
**Format:** Vagrant (Windows/AD)
**Track:** AD/Windows

## Scenario
Your organization's domain controller was compromised last weekend. The incident response team removed the initial malware, but they suspect the attacker left multiple persistence mechanisms behind. Your job: find and remove **ALL** of them.

## Objectives
- Identify all persistence mechanisms the attacker planted
- Remove them without breaking legitimate services
- Document what you found *(attacker's username, methods used, etc.)*

## Connect
| Field | Value |
|---|---|
| **Start** | `vagrant up` (~2-3 min once the base box is built) |
| **RDP To** | 192.168.56.10 (or `vagrant rdp`) |
| **Username** | CORP\jsmith |
| **Password** | Welcome1! |
| **Domain Admin** | CORP\Administrator / P@ssw0rd! |

## Rules of Engagement
- Do not break AD DS or DNS.
- Do not remove legitimate accounts.

## Scoring
Run `C:\vagrant\scripts\score_me.ps1` inside the VM as Administrator.

**8 points total.** Full breakdown is in ANSWER.md.
