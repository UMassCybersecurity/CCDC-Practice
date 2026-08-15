# Challenge 01 Answer Key — Find and Remove Persistence

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's broken / planted
`scripts/plant-backdoors.ps1` runs at provision time and plants 6 mechanisms:
1. A rogue Domain Admin account `YOURPC01$` (named to look like a machine account) in `CN=Computers,DC=corp,DC=local`.
2. A scheduled task `HealthCheck` under `\Microsoft\Windows\WindowsUpdate\`, triggered at startup, running a hidden PowerShell one-liner.
3. A service `UpdateHelperSvc` (`DisplayName` "Windows Update Helper Service") pointing at a placeholder script `C:\Windows\Temp\sync.ps1`.
4. A WMI permanent event subscription (`__EventFilter` "WindowsParentalControls" + `CommandLineEventConsumer` "ParentalControlsHandler" + the binding between them).
5. A registry Run key `WindowsDefenderUpdate` under `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run`.
6. A GPO "Security Baseline Update" linked to the domain root, pushing its own Run-key entry (`BaselineCheck`) to every machine.

## Step-by-step fix
RDP in as `CORP\Administrator`, then in an elevated PowerShell:
1. **Rogue user**: `Remove-ADUser -Identity "YOURPC01$" -Confirm:$false`
2. **Scheduled task**: `Unregister-ScheduledTask -TaskName "HealthCheck" -TaskPath "\Microsoft\Windows\WindowsUpdate\" -Confirm:$false`
3. **Service**: `Stop-Service UpdateHelperSvc; sc.exe delete UpdateHelperSvc` (also remove the leftover placeholder files `C:\Windows\System32\UpdateHelper.dll` and `C:\Windows\Temp\sync.ps1` if you want a fully clean box — not scored, but good practice)
4. **WMI subscription**:
   ```powershell
   Get-WmiObject -Namespace root\subscription -Class __FilterToConsumerBinding | Where-Object { $_.Filter -match "WindowsParentalControls" } | Remove-WmiObject
   Get-WmiObject -Namespace root\subscription -Class __EventFilter | Where-Object { $_.Name -eq "WindowsParentalControls" } | Remove-WmiObject
   Get-WmiObject -Namespace root\subscription -Class CommandLineEventConsumer | Where-Object { $_.Name -eq "ParentalControlsHandler" } | Remove-WmiObject
   ```
5. **Run key**: `Remove-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsDefenderUpdate"`
6. **Rogue GPO**: `(Get-GPO -Name "Security Baseline Update") | Remove-GPLink -Target "DC=corp,DC=local"; Remove-GPO -Name "Security Baseline Update" -Confirm:$false`
7. Run `C:\vagrant\scripts\score_me.ps1` to confirm a perfect score (8/8).

## Validation
Ran a fresh `vagrant up` on 2026-08-14 (reused the already-built `ccdc/dc-base` box). Confirmed all 6 mechanisms actually planted with no provisioning errors — including double-checking the `HealthCheck` scheduled task, since a near-identical task registration under a protected system path failed with Access Denied in a different challenge (11); here it succeeded because `\Microsoft\Windows\WindowsUpdate\` isn't one of the specific pre-existing protected folders. `score_me.ps1` showed 2/8 before any fix (AD DS/DNS pass, everything else fails), applied the steps above verbatim, and confirmed a perfect 8/8. Torn down with `vagrant destroy -f` afterward.

Also fixed a bug in `score_me.ps1` itself while validating: `Get-ADUser -Identity ... -ErrorAction SilentlyContinue` still throws a terminating `ADIdentityNotFoundException` to the console when the account is gone (the intended, passing outcome), which would have shown trainees a scary-looking error on a correct fix. Wrapped it in try/catch instead.
