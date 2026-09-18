# Challenge 20 Answer Key — Service Account Review

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## Learning Objectives
- Identify Kerberoastable service accounts (SPN + crackable password)
- Identify AS-REP roastable accounts (Kerberos pre-authentication disabled)
- Find and decrypt an exposed Group Policy Preferences (GPP) `cpassword` left in SYSVOL

## Hints
- `setspn.exe -Q */*` lists every registered SPN — look for one on a user account rather than a computer account.
- `Get-ADUser -Filter {DoesNotRequirePreAuth -eq $true}` finds AS-REP roastable accounts directly.
- GPP credentials live under SYSVOL at `...\Policies\{GUID}\Machine\Preferences\Groups\Groups.xml` (or `Preferences\ScheduledTasks`, `Preferences\Services`, etc — any GPP XML can carry a `cpassword`). The AES key Microsoft used to "encrypt" `cpassword` values was published after MS14-025/MS15-014 and is public.

## Scoring breakdown
| Points | Criteria |
|---|---|
| +1 | Kerberoastable SPN removed/disabled |
| +1 | AS-REP roasting flag cleared |
| +1 | GPP cpassword file removed from SYSVOL |
| +1 | AD DS still running |

## What's planted
`scripts/plant-backdoors.ps1` runs at provision time and plants 3 issues:
1. `svc-sql` — a service account with SPN `MSSQLSvc/db01.corp.local:1433` and a weak, crackable password (`SqlService2019`). Kerberoastable: any authenticated user can request a service ticket for this SPN and crack it offline.
2. `svc-legacy` — an account with `DoesNotRequirePreAuth` set (AS-REP roastable, password `LegacyApp!2018`): anyone can request an AS-REP for this account without any credentials and crack it offline.
3. A GPO "Legacy Workstation Defaults" with a `Groups.xml` Group Policy Preferences file dropped in its SYSVOL folder, containing a `cpassword` for a `LegacyAdmin` local-admin push. Decrypts (via the public MS14-025/MS15-014 default AES key) to `LegacyAdmin2019!`.

## Step-by-step fix
RDP in as `CORP\Administrator`, then in an elevated PowerShell:
1. **Kerberoastable SPN**: `setspn.exe -D MSSQLSvc/db01.corp.local:1433 svc-sql` (and/or disable the account: `Disable-ADAccount -Identity svc-sql`; rotating to a long random password is the real-world fix if the SPN is actually needed)
2. **AS-REP roastable account**: `Set-ADAccountControl -Identity svc-legacy -DoesNotRequirePreAuth $false`
3. **GPP cpassword**: find it with `Get-ChildItem -Path C:\Windows\SYSVOL\domain\Policies -Recurse -Filter Groups.xml | Select-String cpassword`, then delete the file (`Remove-Item`) and remove the GPO itself: `Remove-GPO -Name "Legacy Workstation Defaults" -Confirm:$false`
4. Run `C:\vagrant\scripts\score_me.ps1` to confirm a perfect score (4/4).

## Validation
Ran a fresh `vagrant up` (reused the already-built `ccdc/dc-base` box), drove the VM headlessly via `vagrant winrm -c "<cmd>" -s powershell -e`. Confirmed all 3 issues actually planted: `setspn.exe -L svc-sql` showed the MSSQLSvc SPN, `Get-ADUser svc-legacy -Properties DoesNotRequirePreAuth` showed `True`, and the Groups.xml cpassword decrypted correctly to `LegacyAdmin2019!` — round-tripped with a local decrypt-only test script against the public GPP AES key (not shipped in this repo). `score_me.ps1` showed `1 / 4` before any fix (AD DS health passes by default), applied the 3 fixes above, confirmed `4 / 4`. Torn down with `vagrant destroy -f` afterward.

Noted one cosmetic issue while testing: `Import-Module ActiveDirectory` throws a non-terminating `InitializeDefaultDrivesException` immediately after this box boots (the AD PowerShell provider's drive init races something during early startup), even though the module's cmdlets load fine afterward and every planted mechanism worked correctly. Added `-ErrorAction SilentlyContinue` to that import in `plant-backdoors.ps1` so trainees don't see a scary-looking error in the `vagrant up` output that has no bearing on the challenge.
