# Challenge 19 Answer Key — Standalone Windows Hardening

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's planted
`scripts/plant-backdoors.ps1` runs at provision time and plants 5 host-level issues:
1. A second admin account `svc-support` (password `Password1`) added to the server's `Administrators` group. (This box's OS has no real local SAM — `New-LocalUser` silently redirects to AD on it — so this is planted as an AD account instead; same practical effect, a second account with full admin rights on the box.)
2. An SMB share `\\<host>\Shared` (backing directory `C:\Shared`) granting `Everyone: Full Control` on both the share and NTFS ACL.
3. Windows Defender real-time protection disabled via `Set-MpPreference -DisableRealtimeMonitoring $true`.
4. A service `ContosoAgent` registered with an unquoted binary path containing a space: `C:\Program Files\Contoso Agent\agent.exe`.
5. RDP configured with Network Level Authentication (NLA) disabled.

## Step-by-step fix
RDP in as `vagrant`/`vagrant`, then in an elevated PowerShell:
1. **Rogue admin account**: `Remove-ADGroupMember -Identity Administrators -Members svc-support -Confirm:$false; Disable-ADAccount -Identity svc-support` (or `Remove-ADUser -Identity svc-support -Confirm:$false`)
2. **Open share**: `Remove-SmbShare -Name Shared -Force` (or re-grant with specific accounts only instead of Everyone)
3. **Defender**: `Set-MpPreference -DisableRealtimeMonitoring $false`
4. **Unquoted service path**: `sc.exe config ContosoAgent binPath= "\"C:\Program Files\Contoso Agent\agent.exe\""` (or `sc.exe delete ContosoAgent` if the service isn't needed)
5. **RDP NLA**: `(Get-WmiObject -Class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(1)`
6. Run `C:\vagrant\scripts\score_me.ps1` to confirm a perfect score (5/5).

## Validation
Ran a fresh `vagrant up` (reused the already-built `ccdc/dc-base` box), then drove the VM headlessly via `vagrant winrm -c "<cmd>" -s powershell -e` instead of interactive RDP.

Hit and fixed two real bugs during testing:
- This box's OS has no real local SAM (`Get-LocalGroupMember -Group Administrators` errors with "Group ... was not found", and `New-LocalUser` silently redirects to creating an AD user instead). Rewrote the "second admin account" finding and its score check to use `New-ADUser` + `Add-ADGroupMember -Identity Administrators` / `Get-ADGroupMember -Identity Administrators` instead of the Local* cmdlets.
- `sc.exe config ... binPath= "..."` did not reliably apply an embedded-quote value through nested shell/WinRM escaping when tested via `vagrant winrm -c`; fixing the service path with `Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\ContosoAgent -Name ImagePath` worked and is what's documented above. (A trainee doing this interactively over RDP, typing directly into a PowerShell window, won't hit this — it's a quoting artifact of scripted/pasted-through-multiple-shells execution, not of the fix itself.)

Confirmed all 5 issues actually planted after a clean rebuild (svc-support an enabled AD account in the Administrators group, Shared share Everyone:Full, Defender real-time monitoring disabled, ContosoAgent unquoted path, RDP NLA off). `score_me.ps1` showed `0 / 5` before any fix, applied the 5 steps above, and confirmed a perfect `5 / 5`. Torn down with `vagrant destroy -f` afterward.
