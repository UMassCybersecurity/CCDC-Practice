# Challenge 20: Kerberoasting Lab

**Category:** Active Directory / Credential Exposure
**Difficulty:** Medium-Hard
**Time estimate:** 40-55 minutes
**Format:** Vagrant (Windows/AD)
**Track:** AD/Windows

## Scenario
A security assessment flagged `corp.local` for Kerberos-related credential exposure. Three separate issues were reported but never triaged. Find and fix all of them.

<details>
<summary><strong>Learning Objectives</strong> (spoiler — click to reveal)</summary>

- Identify Kerberoastable service accounts (SPN + crackable password)
- Identify AS-REP roastable accounts (Kerberos pre-authentication disabled)
- Find and decrypt an exposed Group Policy Preferences (GPP) `cpassword` left in SYSVOL

</details>

## Objectives
- Identify all three Kerberos/credential exposure issues
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

<details>
<summary><strong>Hints</strong> (try without these first — click to reveal)</summary>

- `setspn.exe -Q */*` lists every registered SPN — look for one on a user account rather than a computer account.
- `Get-ADUser -Filter {DoesNotRequirePreAuth -eq $true}` finds AS-REP roastable accounts directly.
- GPP credentials live under SYSVOL at `...\Policies\{GUID}\Machine\Preferences\Groups\Groups.xml` (or `Preferences\ScheduledTasks`, `Preferences\Services`, etc — any GPP XML can carry a `cpassword`). The AES key Microsoft used to "encrypt" `cpassword` values was published after MS14-025/MS15-014 and is public.

</details>

## Scoring
Run `C:\vagrant\scripts\score_me.ps1` inside the VM as Administrator.

<details>
<summary>Scoring criteria (spoiler — click to reveal)</summary>

| Points | Criteria |
|---|---|
| +1 | Kerberoastable SPN removed/disabled |
| +1 | AS-REP roasting flag cleared |
| +1 | GPP cpassword file removed from SYSVOL |
| +1 | AD DS still running |

> **Expected finding count: 3**

</details>
