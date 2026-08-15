# Challenge 01: Find and Remove Persistence

**Category:** Persistence & Backdoor Hunting
**Difficulty:** Medium
**Time estimate:** 30-60 minutes
**Format:** Vagrant (Windows/AD)

## Scenario
Your organization's domain controller was compromised last weekend. The incident response team removed the initial malware, but they suspect the attacker left multiple persistence mechanisms behind. Your job: find and remove **ALL** of them.

<details>
<summary><strong>Learning Objectives</strong> (spoiler — click to reveal)</summary>

- Identify a rogue AD account hidden among legitimate accounts, including in privileged groups
- Audit scheduled tasks for malicious triggers disguised under a legitimate-sounding path
- Detect a malicious service registered under an innocuous DisplayName
- Enumerate WMI event subscriptions used for fileless persistence
- Check registry Run keys for unauthorized startup entries
- Recognize a rogue GPO used to push persistence domain-wide

</details>

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

<details>
<summary><strong>Hints</strong> (try without these first — click to reveal)</summary>

- Check scheduled tasks
- Check for unauthorized users *(especially in privileged groups)*
- Check services
- Check WMI subscriptions
- Check startup locations *(Run keys, startup folder)*
- Check for rogue GPOs

</details>

## Scoring
Run `C:\vagrant\scripts\score_me.ps1` inside the VM as Administrator.

<details>
<summary>Scoring criteria (spoiler — click to reveal)</summary>

| Points | Criteria |
|---|---|
| +1 | Found rogue user account |
| +1 | Found malicious scheduled task |
| +1 | Found malicious service |
| +1 | Found WMI persistence |
| +1 | Found registry run key |
| +1 | Found rogue GPO |
| +1 | AD DS still running |
| +1 | DNS still running |

> **Expected persistence count: 6**

</details>
