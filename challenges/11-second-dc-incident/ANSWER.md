# Challenge 11 Answer Key — Another Domain Controller Incident

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## Learning Objectives
- Detect Image File Execution Options (IFEO) "debugger" abuse on accessibility binaries
- Audit inbound Windows Firewall rules for unauthorized entries
- Recognize AdminSDHolder/SDProp ACL abuse as a stealthy persistent-admin technique
- Spot self-healing persistence delivered via a user's logon script
- Distinguish a disguised scheduled task from a legitimate Microsoft one by what it actually does, not its name

## Hints
- `reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"` — check accessibility binaries (`utilman.exe`, `sethc.exe`, `osk.exe`) for a `Debugger` value.
- `Get-NetFirewallRule -Direction Inbound | Where-Object {$_.Action -eq 'Allow'}` — review every allow rule, not just the obvious ones.
- `dsacls.exe "CN=AdminSDHolder,CN=System,DC=corp,DC=local"` shows every ACE on the template that SDProp reapplies to protected accounts every 60 minutes.
- Check `scriptPath` on AD user objects (`Get-ADUser -Filter * -Properties scriptPath`), not just startup folders and Run keys.
- A scheduled task's name and path can look exactly like a real Microsoft maintenance task — check what its action actually runs.

## Scoring breakdown
| Points | Criteria |
|---|---|
| +1 | IFEO `Debugger` backdoor removed from `utilman.exe` |
| +1 | Rogue inbound RDP firewall rule removed |
| +1 | AdminSDHolder ACE for `svc-reports` removed |
| +1 | Self-healing logon-script backdoor cleared from `jsmith` |
| +1 | Disguised `USO_Svc_Refresh` scheduled task removed |
| +1 | AD DS still running |
| +1 | DNS still running |

## What's broken / planted
`scripts/plant-backdoors.ps1` runs at provision time and plants 5 mechanisms:
1. An IFEO `Debugger` value on `utilman.exe` pointing at `cmd.exe` (logon-screen accessibility-shortcut backdoor).
2. An inbound firewall rule `Remote Desktop - Maintenance Access` allowing RDP (3389) from any address.
3. A new user `svc-reports` plus a `GA` (Generic All) ACE for it on `CN=AdminSDHolder,CN=System,DC=corp,DC=local`, applied via `dsacls.exe`.
4. A logon script `selfheal.bat` in `SYSVOL\domain\scripts` that recreates a local admin account `svc-helper` if missing, set as `jsmith`'s `scriptPath`.
5. A scheduled task `\Microsoft\Windows\UpdateOrchestratorEx\USO_Svc_Refresh` that daily re-applies the IFEO backdoor from item 1. (Note: the real `\Microsoft\Windows\UpdateOrchestrator\` folder already exists on Windows with a protective ACL that blocks task creation there even for local admins — this challenge uses a plausible sibling folder name instead so the scenario can actually be planted.)

## Step-by-step fix
1. RDP in as `CORP\Administrator`.
2. **IFEO backdoor**: `Remove-Item "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\utilman.exe" -Recurse -Force`
3. **Firewall rule**: `Remove-NetFirewallRule -DisplayName "Remote Desktop - Maintenance Access"`
4. **AdminSDHolder ACE**: `dsacls.exe "CN=AdminSDHolder,CN=System,DC=corp,DC=local" /R "CORP\svc-reports"` then, since the account itself is unauthorized, `Remove-ADUser -Identity svc-reports -Confirm:$false`
5. **Logon-script backdoor**: `Set-ADUser -Identity jsmith -Clear scriptPath` then remove the script file: `Remove-Item "C:\Windows\SYSVOL\domain\scripts\selfheal.bat" -Force`. Also remove the backdoor account it already created, if present: `Remove-LocalUser -Name svc-helper -ErrorAction SilentlyContinue`
6. **Disguised scheduled task**: `Unregister-ScheduledTask -TaskName "USO_Svc_Refresh" -TaskPath "\Microsoft\Windows\UpdateOrchestratorEx\" -Confirm:$false`
7. Do the IFEO removal **before or after** the scheduled task removal, but re-check it afterward — if the task fires before you delete it, it will re-plant the Debugger value.
8. Run `C:\vagrant\scripts\score_me.ps1` to confirm a perfect score (7/7).

## Validation
Ran a fresh `vagrant up` on 2026-08-14. First attempt at build-time hit a real bug: `Register-ScheduledTask` into `\Microsoft\Windows\UpdateOrchestrator\` failed with Access Denied even as local admin, because that folder already exists on stock Windows with a protective ACL — confirmed by testing several sibling paths interactively, and fixed by moving the disguise to the non-existent (but equally plausible) `\Microsoft\Windows\UpdateOrchestratorEx\`, which is freely writable since Register-ScheduledTask creates it fresh. After that fix, destroyed and re-ran `vagrant up` clean (all 5 mechanisms planted with no errors), confirmed `score_me.ps1` showed 2/7 before any fix, applied the steps above verbatim, and confirmed a perfect 7/7. Torn down with `vagrant destroy -f` afterward.
