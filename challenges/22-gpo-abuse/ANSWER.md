# Challenge 22 Answer Key — GPO Abuse

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's planted
`scripts/plant-backdoors.ps1` runs at provision time and creates 4 GPOs linked at the domain root:
- 3 legitimate decoys: "Desktop Wallpaper Standard", "Screen Lock Timeout Policy", "Browser Homepage Configuration" — each sets one boring, real registry preference and nothing else.
- 1 rogue GPO, "Workstation Compliance Baseline": its registry-based settings (what `Get-GPOReport` shows) are empty/unremarkable. Its actual payload is a Group Policy **Preferences** Scheduled Task — a `ScheduledTasks.xml` file dropped directly in its SYSVOL folder (`Machine\Preferences\ScheduledTasks\`) — a hidden task named `WindowsHealthCheck` running as SYSTEM every hour, executing a base64-encoded PowerShell one-liner that downloads and runs a remote script.

This is deliberately a different persistence mechanism from challenge 01's rogue GPO (which pushes a plain registry Run key) — GPP-delivered payloads don't show up the same way in a standard `Get-GPOReport`, since GPP items live in SYSVOL rather than being expressed as simple policy registry values.

## Step-by-step fix
RDP in as `CORP\Administrator`, then in an elevated PowerShell:
1. **Enumerate**: `Get-GPO -All | Select DisplayName,Id` — 4 GPOs, all plausible-sounding.
2. **Inspect each one**: `Get-GPOReport -Guid <id> -ReportType Html -Path C:\Windows\Temp\report.html` for each — the 3 decoys show a real, boring registry setting. "Workstation Compliance Baseline" shows nothing meaningful in the report, which is itself suspicious for a linked, "compliance"-named GPO.
3. **Check its SYSVOL folder directly**: `Get-ChildItem "C:\Windows\SYSVOL\domain\Policies\{<rogue GPO's GUID>}" -Recurse` reveals `Machine\Preferences\ScheduledTasks\ScheduledTasks.xml` — a GPP payload that doesn't show up in the report.
4. **Remove it**: `(Get-GPO -Name "Workstation Compliance Baseline") | Remove-GPLink -Target "DC=corp,DC=local"; Remove-GPO -Name "Workstation Compliance Baseline" -Confirm:$false` (this also removes its SYSVOL folder).
5. Run `C:\vagrant\scripts\score_me.ps1` to confirm a perfect score (3/3).

## Validation
Ran a fresh `vagrant up` (reused the already-built `ccdc/dc-base` box), drove the VM headlessly via `vagrant winrm -c "<cmd>" -s powershell -e`. Confirmed all 4 GPOs created and linked to the domain root, and that the rogue GPO's `ScheduledTasks.xml` (containing `WindowsHealthCheck`) was present under its SYSVOL folder while the 3 decoys had no such Preferences folder. `score_me.ps1` showed `1 / 3` before any fix (the "decoys untouched" check passes from the start — see note below). Applied the fix (`Remove-GPLink` + `Remove-GPO` on the rogue GPO only), confirmed `3 / 3`, and separately confirmed all 3 decoy GPOs remained (`Get-GPO -Name "Desktop Wallpaper Standard"` etc. all still resolved). Torn down with `vagrant destroy -f` afterward.

Note on the "decoys untouched" check: it always passes at both the start and end of a *correct* run (since a correct fix never touches the decoys) — it only ever fails if a candidate wrongly deletes a legitimate GPO. That's intentional: it's a guard-rail check, not a progress check, so it's already contributing to the initial `1 / 3` score alongside the two real remediation checks failing, rather than starting at `0 / 3`.
