# Challenge 11: Privileged Persistence

**Category:** Persistence & Backdoor Hunting
**Difficulty:** Hard
**Time estimate:** 40-60 minutes
**Format:** Vagrant (Windows/AD)

## Scenario
corp.local's domain controller was compromised again — a different attacker than the one from Challenge 01, using a different playbook. This one favored quieter, more privileged techniques than last time. Find all five and remove them without breaking the domain.

<details>
<summary><strong>Learning Objectives</strong> (spoiler — click to reveal)</summary>

- Detect Image File Execution Options (IFEO) "debugger" abuse on accessibility binaries
- Audit inbound Windows Firewall rules for unauthorized entries
- Recognize AdminSDHolder/SDProp ACL abuse as a stealthy persistent-admin technique
- Spot self-healing persistence delivered via a user's logon script
- Distinguish a disguised scheduled task from a legitimate Microsoft one by what it actually does, not its name

</details>

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

<details>
<summary><strong>Hints</strong> (try without these first — click to reveal)</summary>

- `reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"` — check accessibility binaries (`utilman.exe`, `sethc.exe`, `osk.exe`) for a `Debugger` value.
- `Get-NetFirewallRule -Direction Inbound | Where-Object {$_.Action -eq 'Allow'}` — review every allow rule, not just the obvious ones.
- `dsacls.exe "CN=AdminSDHolder,CN=System,DC=corp,DC=local"` shows every ACE on the template that SDProp reapplies to protected accounts every 60 minutes.
- Check `scriptPath` on AD user objects (`Get-ADUser -Filter * -Properties scriptPath`), not just startup folders and Run keys.
- A scheduled task's name and path can look exactly like a real Microsoft maintenance task — check what its action actually runs.

</details>

## Scoring
Run `C:\vagrant\scripts\score_me.ps1` inside the VM as Administrator.

<details>
<summary>Scoring criteria (spoiler — click to reveal)</summary>

| Points | Criteria |
|---|---|
| +1 | IFEO `Debugger` backdoor removed from `utilman.exe` |
| +1 | Rogue inbound RDP firewall rule removed |
| +1 | AdminSDHolder ACE for `svc-reports` removed |
| +1 | Self-healing logon-script backdoor cleared from `jsmith` |
| +1 | Disguised `USO_Svc_Refresh` scheduled task removed |
| +1 | AD DS still running |
| +1 | DNS still running |

> **Expected persistence count: 5**

</details>
