# score_me.ps1
# Challenge 21 - ACL Privesc Hunt - Scoring Engine
# Run this inside the VM as Administrator: C:\vagrant\scripts\score_me.ps1

$Score = 0
$MaxScore = 4

Write-Host "========================================"
Write-Host " ACL Privesc Hunt Scoring Engine v1.0"
Write-Host "========================================"
Write-Host ""

# Check 1: DCSync rights removed from svc-monitor
$domainAcl = (dsacls.exe "DC=corp,DC=local" 2>$null) -join "`n"
if ($domainAcl -notmatch "svc-monitor") {
    Write-Host "[OK] PASS: svc-monitor no longer has replication rights on the domain root. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: svc-monitor still has DCSync (replication) rights on the domain root."
}

# Check 2: GenericAll over jsmith removed from svc-monitor
Import-Module ActiveDirectory -ErrorAction SilentlyContinue
$jsmithDn = (Get-ADUser -Identity "jsmith" -ErrorAction SilentlyContinue).DistinguishedName
$jsmithAcl = if ($jsmithDn) { (dsacls.exe "$jsmithDn" 2>$null) -join "`n" } else { "" }
if ($jsmithAcl -notmatch "svc-monitor") {
    Write-Host "[OK] PASS: svc-monitor no longer has GenericAll over jsmith. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: svc-monitor still has GenericAll over jsmith."
}

# Check 3: AD DS still healthy
$ntds = Get-Service -Name NTDS -ErrorAction SilentlyContinue
if ($ntds -and $ntds.Status -eq "Running") {
    Write-Host "[OK] PASS: Active Directory Domain Services is running. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: Active Directory Domain Services is not running!"
}

# Check 4: DNS still healthy
$dns = Get-Service -Name DNS -ErrorAction SilentlyContinue
if ($dns -and $dns.Status -eq "Running") {
    Write-Host "[OK] PASS: DNS Server is running. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: DNS Server is not running!"
}

Write-Host ""
Write-Host "========================================"
Write-Host " FINAL SCORE: $Score / $MaxScore"
Write-Host "========================================"
