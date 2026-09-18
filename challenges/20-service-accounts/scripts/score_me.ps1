# score_me.ps1
# Challenge 20 - Kerberoasting Lab - Scoring Engine
# Run this inside the VM as Administrator: C:\vagrant\scripts\score_me.ps1

$Score = 0
$MaxScore = 4

Write-Host "========================================"
Write-Host " Kerberoasting Lab Scoring Engine v1.0"
Write-Host "========================================"
Write-Host ""

Import-Module ActiveDirectory -ErrorAction SilentlyContinue

# Check 1: Kerberoastable SPN removed / account disabled
$spns = setspn.exe -L svc-sql 2>$null
$svcSql = Get-ADUser -Identity svc-sql -Properties Enabled -ErrorAction SilentlyContinue
$spnPresent = ($spns -join "`n") -match "MSSQLSvc"
if (-not $spnPresent -or -not $svcSql -or -not $svcSql.Enabled) {
    Write-Host "[OK] PASS: svc-sql's Kerberoastable SPN has been removed/disabled. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: svc-sql still has an active SPN (MSSQLSvc/db01.corp.local:1433)."
}

# Check 2: AS-REP roasting flag cleared
$svcLegacy = Get-ADUser -Identity svc-legacy -Properties DoesNotRequirePreAuth,Enabled -ErrorAction SilentlyContinue
if (-not $svcLegacy -or -not $svcLegacy.Enabled -or -not $svcLegacy.DoesNotRequirePreAuth) {
    Write-Host "[OK] PASS: svc-legacy no longer skips Kerberos pre-authentication. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: svc-legacy still has DoesNotRequirePreAuth set (AS-REP roastable)."
}

# Check 3: GPP cpassword file removed from SYSVOL
$found = Get-ChildItem -Path "C:\Windows\SYSVOL\domain\Policies" -Recurse -Filter "Groups.xml" -ErrorAction SilentlyContinue |
    Where-Object { (Get-Content $_.FullName -Raw) -match "cpassword" }
if (-not $found) {
    Write-Host "[OK] PASS: No GPP cpassword file remains in SYSVOL. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: A GPP Groups.xml with a cpassword is still present in SYSVOL."
}

# Check 4: AD DS still healthy
$ntds = Get-Service -Name NTDS -ErrorAction SilentlyContinue
if ($ntds -and $ntds.Status -eq "Running") {
    Write-Host "[OK] PASS: Active Directory Domain Services is running. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: Active Directory Domain Services is not running!"
}

Write-Host ""
Write-Host "========================================"
Write-Host " FINAL SCORE: $Score / $MaxScore"
Write-Host "========================================"
