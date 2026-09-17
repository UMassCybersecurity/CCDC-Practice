# Challenge 22: GPO Abuse

**Category:** Active Directory / Group Policy
**Difficulty:** Medium
**Time estimate:** 35-50 minutes
**Format:** Vagrant (Windows/AD)
**Track:** AD/Windows

## Scenario
`corp.local` has several Group Policy Objects linked at the domain root. Most are boring, legitimate desktop-configuration policies. One of them isn't — it's pushing persistence to every machine in the domain via a hidden Scheduled Task.

<details>
<summary><strong>Learning Objectives</strong> (spoiler — click to reveal)</summary>

- Enumerate GPOs and their links with `Get-GPO`/`Get-GPOReport`
- Recognize Group Policy Preferences (GPP) as a persistence delivery mechanism, distinct from a simple registry Run key
- Tell a legitimate configuration GPO apart from a weaponized one by actually inspecting its contents, not just its name

</details>

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

<details>
<summary><strong>Hints</strong> (try without these first — click to reveal)</summary>

- `Get-GPO -All | Select DisplayName,Id` lists every GPO by name — a plausible name alone tells you nothing.
- `Get-GPOReport -Guid <id> -ReportType Html -Path report.html` dumps a GPO's actual settings for review.
- A GPO's raw Group Policy Preferences payloads live in SYSVOL under `...\Policies\{GUID}\Machine\Preferences\` — that's where a Scheduled Task pushed via GPP actually lives, separate from the registry-based settings `Get-GPOReport` shows cleanly.

</details>

## Scoring
Run `C:\vagrant\scripts\score_me.ps1` inside the VM as Administrator.

<details>
<summary>Scoring criteria (spoiler — click to reveal)</summary>

| Points | Criteria |
|---|---|
| +1 | Rogue GPO deleted or unlinked |
| +1 | Rogue GPO's SYSVOL Scheduled Task payload removed |
| +1 | All 3 legitimate GPOs left untouched |

> **Expected finding count: 1 rogue GPO among 4 total**

</details>
