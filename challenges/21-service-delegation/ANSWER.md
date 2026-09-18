# Challenge 21 Answer Key — Service Account Delegation

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## Learning Objectives
- Audit AD object ACLs (ACEs) with `dsacls.exe` or `Get-Acl`/`Get-ADObject -Properties ntSecurityDescriptor`
- Recognize "Replicating Directory Changes" + "Replicating Directory Changes All" as DCSync rights — full domain credential compromise
- Recognize GenericAll over a user object as a direct password-reset/takeover primitive
- Understand how a single weak, over-delegated account chains into full domain compromise

## Hints
- `dsacls.exe "DC=corp,DC=local"` dumps the domain root's full ACL — look for anything that isn't a default built-in principal.
- DCSync needs *two* extended rights together, not just one — check for both.
- The domain-root grant isn't the only one. Check ACLs on individual user objects too, not just the domain root.

## Scoring breakdown
| Points | Criteria |
|---|---|
| +1 | DCSync rights removed from the domain root |
| +1 | GenericAll over jsmith removed |
| +1 | AD DS still running |
| +1 | DNS still running |

## What's planted
`scripts/plant-backdoors.ps1` runs at provision time and plants 2 chained ACL misconfigurations on a new low-privilege account `svc-monitor` (password `Monitoring2024!`, not in any privileged group):
1. **DCSync rights** on the domain root (`DC=corp,DC=local`): both `Replicating Directory Changes` and `Replicating Directory Changes All` extended rights, granted via `dsacls.exe`. Together these let `svc-monitor` request a full domain replication — i.e. dump every account's password hash, including `krbtgt` and Domain Admins — without ever touching the DC's disk.
2. **GenericAll** over `jsmith`'s user object (`CN=John Smith,OU=IT Department,OU=Employees,DC=corp,DC=local` — note this is *not* under the default `CN=Users` container, since `jsmith` was seeded into an OU structure): lets `svc-monitor` reset `jsmith`'s password or take the account over directly, as a second, independent escalation path.

## Step-by-step fix
RDP in as `CORP\Administrator`, then in an elevated PowerShell/cmd:
1. **Find it**: `dsacls.exe "DC=corp,DC=local"` lists ACEs on the domain root. For jsmith's object, first get its real DN — `(Get-ADUser jsmith).DistinguishedName` — then `dsacls.exe "<that DN>"`. Both show ACEs for `CORP\svc-monitor` that don't belong.
2. **Remove DCSync rights**: `dsacls.exe "DC=corp,DC=local" /R "CORP\svc-monitor"`
3. **Remove GenericAll over jsmith**: `dsacls.exe "<jsmith's DN>" /R "CORP\svc-monitor"`
4. Run `C:\vagrant\scripts\score_me.ps1` to confirm a perfect score (4/4).

(`/R` removes *all* ACEs for that trustee on the object — fine here since `svc-monitor` shouldn't have any explicit grants on either object at all.)

## Validation
Ran a fresh `vagrant up` (reused the already-built `ccdc/dc-base` box), drove the VM headlessly via `vagrant winrm -c "<cmd>" -s powershell -e`. First attempt hardcoded jsmith's DN as `CN=jsmith,CN=Users,DC=corp,DC=local` (matching challenge 11's pattern for `svc-reports`) and it failed — `jsmith` was actually seeded by `create-users.ps1` into `CN=John Smith,OU=IT Department,OU=Employees,DC=corp,DC=local`, a real OU structure, not the flat `CN=Users` container. Fixed both `plant-backdoors.ps1` and `score_me.ps1` to resolve jsmith's DN dynamically via `Get-ADUser` instead of hardcoding it.

After the fix: confirmed both ACEs actually planted — `dsacls.exe "DC=corp,DC=local"` showed `CORP\svc-monitor` with `Replicating Directory Changes` and `Replicating Directory Changes All`, and `dsacls.exe` on jsmith's real DN showed `CORP\svc-monitor` with `GENERIC_ALL`. `score_me.ps1` showed `2 / 4` before any fix (AD DS/DNS health pass by default), applied the two `dsacls /R` fixes above, confirmed `4 / 4`. Torn down with `vagrant destroy -f` afterward.
