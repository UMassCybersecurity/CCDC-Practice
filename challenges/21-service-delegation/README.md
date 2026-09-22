# Challenge 21: Service Account Delegation

**Category:** Active Directory / Security Review
**Difficulty:** Hard
**Time estimate:** 45-60 minutes
**Format:** Vagrant (Windows/AD)
**Track:** AD/Windows

## Scenario
A low-privilege service account on `corp.local` was delegated some rights months ago "temporarily" and nobody ever audited what those rights actually granted. Figure out what that account can really do in the domain, and lock it down.

## Objectives
- Figure out exactly what the over-permissioned account can do in the domain
- Remove the excess rights without breaking AD DS
- Document what you found *(account name, rights granted, on which objects)*

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
- Do not remove the `svc-monitor` account itself — it's a legitimate (if over-permissioned) service account. Just fix its rights.
- Do not touch AdminSDHolder — that's not where this one lives.

## Scoring
Run `C:\vagrant\scripts\score_me.ps1` inside the VM as Administrator.

**4 points total.** Full breakdown is in ANSWER.md.
