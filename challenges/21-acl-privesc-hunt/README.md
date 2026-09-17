# Challenge 21: ACL Privesc Hunt

**Category:** Active Directory / Access Control Abuse
**Difficulty:** Hard
**Time estimate:** 45-60 minutes
**Format:** Vagrant (Windows/AD)
**Track:** AD/Windows

## Scenario
A low-privilege service account on `corp.local` was delegated some rights months ago "temporarily" and nobody ever audited what those rights actually granted. It turns out compromising that one account's password is enough to compromise the entire domain. Find the delegation chain and cut it off.

<details>
<summary><strong>Learning Objectives</strong> (spoiler — click to reveal)</summary>

- Audit AD object ACLs (ACEs) with `dsacls.exe` or `Get-Acl`/`Get-ADObject -Properties ntSecurityDescriptor`
- Recognize "Replicating Directory Changes" + "Replicating Directory Changes All" as DCSync rights — full domain credential compromise
- Recognize GenericAll over a user object as a direct password-reset/takeover primitive
- Understand how a single weak, over-delegated account chains into full domain compromise

</details>

## Objectives
- Identify every non-default ACE granted to the low-privilege account
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

<details>
<summary><strong>Hints</strong> (try without these first — click to reveal)</summary>

- `dsacls.exe "DC=corp,DC=local"` dumps the domain root's full ACL — look for anything that isn't a default built-in principal.
- DCSync needs *two* extended rights together, not just one — check for both.
- The domain-root grant isn't the only one. Check ACLs on individual user objects too, not just the domain root.

</details>

## Scoring
Run `C:\vagrant\scripts\score_me.ps1` inside the VM as Administrator.

<details>
<summary>Scoring criteria (spoiler — click to reveal)</summary>

| Points | Criteria |
|---|---|
| +1 | DCSync rights removed from the domain root |
| +1 | GenericAll over jsmith removed |
| +1 | AD DS still running |
| +1 | DNS still running |

> **Expected finding count: 2 (chained across 2 objects)**

</details>
