# Challenge 19: Standalone Windows Hardening

**Category:** Host Hardening / Misconfiguration Audit
**Difficulty:** Easy-Medium
**Time estimate:** 25-35 minutes
**Format:** Vagrant (Windows)
**Track:** AD/Windows

## Scenario
A standalone Windows server was stood up quickly for a project and never got a proper hardening pass. Nothing has been compromised (yet) — this is a proactive audit. Find the local misconfigurations before someone else does.

<details>
<summary><strong>Learning Objectives</strong> (spoiler — click to reveal)</summary>

- Audit local user accounts and group membership for unnecessary admin rights
- Identify SMB shares with overly permissive access
- Verify endpoint protection (Windows Defender) is actually running
- Recognize an unquoted service path as a local privilege-escalation vector
- Confirm RDP requires Network Level Authentication

</details>

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

<details>
<summary><strong>Hints</strong> (try without these first — click to reveal)</summary>

- `Get-ADGroupMember -Identity Administrators` shows who shouldn't be there.
- `Get-SmbShare` + `Get-SmbShareAccess <name>` for share permissions.
- `Get-MpPreference` shows Defender's actual real-time-protection state.
- `Get-CimInstance Win32_Service | Select Name,PathName` — look for an unquoted path containing a space.
- RDP's NLA setting lives in the `Win32_TSGeneralSetting` WMI class, not a simple registry flag.

</details>

## Scoring
Run `C:\vagrant\scripts\score_me.ps1` inside the VM as Administrator.

<details>
<summary>Scoring criteria (spoiler — click to reveal)</summary>

| Points | Criteria |
|---|---|
| +1 | Rogue local admin account removed/disabled |
| +1 | Wide-open SMB share locked down |
| +1 | Windows Defender real-time protection re-enabled |
| +1 | Unquoted service path fixed or service removed |
| +1 | RDP Network Level Authentication re-enabled |

> **Expected finding count: 5**

</details>
