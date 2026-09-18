# plant-backdoors.ps1
# Plants a chained ACL misconfiguration on the corp.local DC.
# DO NOT READ THIS FILE BEFORE ATTEMPTING THE CHALLENGE

Write-Host "=== Setting up challenge scenario ==="

$ProgressPreference = 'SilentlyContinue'
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

Start-Sleep -Seconds 30

# --- Low-privilege account with a weak, guessable password ---
New-ADUser `
    -Name "svc-monitor" `
    -SamAccountName "svc-monitor" `
    -Path "CN=Users,DC=corp,DC=local" `
    -AccountPassword (ConvertTo-SecureString "Monitoring2024!" -AsPlainText -Force) `
    -Enabled $true `
    -PasswordNeverExpires $true `
    -Description "Monitoring/health-check service account"

# --- 1. DCSync rights granted on the domain root ---
# "Replicating Directory Changes" + "Replicating Directory Changes All" let
# svc-monitor pull password hashes for every account in the domain, exactly
# like a real domain controller would during replication.
dsacls.exe "DC=corp,DC=local" /G "CORP\svc-monitor:CA;Replicating Directory Changes" | Out-Null
dsacls.exe "DC=corp,DC=local" /G "CORP\svc-monitor:CA;Replicating Directory Changes All" | Out-Null

# --- 2. GenericAll over a separate, unrelated user object ---
# Lets svc-monitor reset jsmith's password (or take over the account
# outright) as a second, independent escalation path.
$jsmithDn = (Get-ADUser -Identity "jsmith").DistinguishedName
dsacls.exe "$jsmithDn" /G "CORP\svc-monitor:GA" | Out-Null

Write-Host "=== Challenge scenario ready ==="
Write-Host "ACL misconfigurations planted: 2"
