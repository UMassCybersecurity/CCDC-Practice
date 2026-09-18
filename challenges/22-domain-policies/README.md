# Challenge 22: Domain Group Policy Review

**Category:** Active Directory / Security Review
**Difficulty:** Medium
**Time estimate:** 35-50 minutes
**Format:** Vagrant (Windows/AD)
**Track:** AD/Windows

## Scenario
`corp.local` has several Group Policy Objects linked at the domain root. Most are boring, legitimate desktop-configuration policies. One of them isn't — something about it doesn't add up.

## Objectives
- Identify the one rogue GPO among the legitimate ones
- Remove it (and its SYSVOL payload) without touching the legitimate GPOs
- Document what you found *(GPO name, payload, delivery mechanism)*

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
- Do not delete or unlink any of the legitimate GPOs — only the rogue one.

## Scoring
Run `C:\vagrant\scripts\score_me.ps1` inside the VM as Administrator.

**3 points total.** Full breakdown is in ANSWER.md.

> **Expected finding count: 1 rogue GPO among 4 total**
