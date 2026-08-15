# score_me.ps1
# Challenge 01 - Find and Remove Persistence - Scoring Engine
# Run this inside the VM as Administrator: C:\vagrant\scripts\score_me.ps1

Import-Module ActiveDirectory -ErrorAction SilentlyContinue

$Score = 0
$MaxScore = 8

Write-Host "========================================"
Write-Host " Find and Remove Persistence Scoring Engine v1.0"
Write-Host "========================================"
Write-Host ""

# Check 1: rogue user account removed
try {
    $rogueUser = Get-ADUser -Identity "YOURPC01`$" -ErrorAction Stop
} catch {
    $rogueUser = $null
}
if (-not $rogueUser) {
    Write-Host "[OK] PASS: Rogue account YOURPC01`$ removed. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: Rogue account YOURPC01`$ still exists."
}

# Check 2: malicious scheduled task removed
$task = Get-ScheduledTask -TaskPath "\Microsoft\Windows\WindowsUpdate\" -TaskName "HealthCheck" -ErrorAction SilentlyContinue
if (-not $task) {
    Write-Host "[OK] PASS: Malicious HealthCheck scheduled task removed. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: Malicious HealthCheck scheduled task still present."
}

# Check 3: malicious service removed
$svc = Get-Service -Name UpdateHelperSvc -ErrorAction SilentlyContinue
if (-not $svc) {
    Write-Host "[OK] PASS: Malicious UpdateHelperSvc service removed. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: Malicious UpdateHelperSvc service still present."
}

# Check 4: WMI event subscription removed
$wmiFilter = Get-WmiObject -Namespace root\subscription -Class __EventFilter -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq "WindowsParentalControls" }
$wmiConsumer = Get-WmiObject -Namespace root\subscription -Class CommandLineEventConsumer -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq "ParentalControlsHandler" }
if (-not $wmiFilter -and -not $wmiConsumer) {
    Write-Host "[OK] PASS: WMI event subscription persistence removed. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: WMI event filter and/or consumer still present."
}

# Check 5: registry Run key removed
$runKey = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsDefenderUpdate" -ErrorAction SilentlyContinue
if (-not $runKey) {
    Write-Host "[OK] PASS: WindowsDefenderUpdate Run key removed. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: WindowsDefenderUpdate Run key still present."
}

# Check 6: rogue GPO removed
$gpo = Get-GPO -Name "Security Baseline Update" -ErrorAction SilentlyContinue
if (-not $gpo) {
    Write-Host "[OK] PASS: Rogue 'Security Baseline Update' GPO removed. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: Rogue 'Security Baseline Update' GPO still present."
}

# Check 7: AD DS still healthy
$ntds = Get-Service -Name NTDS -ErrorAction SilentlyContinue
if ($ntds -and $ntds.Status -eq "Running") {
    Write-Host "[OK] PASS: Active Directory Domain Services is running. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: Active Directory Domain Services is not running!"
}

# Check 8: DNS still healthy
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
