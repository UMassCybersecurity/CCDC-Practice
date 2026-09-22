# Challenge 20: Service Account Review

**Category:** Active Directory / Security Review
**Difficulty:** Medium-Hard
**Time estimate:** 40-55 minutes
**Format:** Vagrant (Windows/AD)
**Track:** AD/Windows

## Scenario
A security assessment flagged `corp.local` for some account and credential hygiene issues. Several issues were reported but never triaged. Find and fix all of them.

## Objectives
- Identify all the account/credential exposure issues
- Remediate each one without breaking AD DS
- Document what you found *(account names, exposed passwords, etc.)*

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
- Do not remove legitimate accounts (`jsmith`, etc).

## Scoring
Run `C:\vagrant\scripts\score_me.ps1` inside the VM as Administrator.

**4 points total.** Full breakdown is in ANSWER.md.
