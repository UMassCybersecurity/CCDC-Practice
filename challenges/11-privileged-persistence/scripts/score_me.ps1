# score_me.ps1
# Challenge 11 - Privileged Persistence - Scoring Engine
# Run this inside the VM as Administrator: C:\vagrant\scripts\score_me.ps1

$Score = 0
$MaxScore = 7

Write-Host "========================================"
Write-Host " Privileged Persistence Scoring Engine v1.0"
Write-Host "========================================"
Write-Host ""

# Check 1: IFEO debugger backdoor removed
$ifeoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\utilman.exe"
$debugger = (Get-ItemProperty -Path $ifeoPath -Name "Debugger" -ErrorAction SilentlyContinue).Debugger
if (-not $debugger) {
    Write-Host "[OK] PASS: utilman.exe IFEO debugger backdoor removed. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: utilman.exe still has a Debugger value set ($debugger)."
}

# Check 2: rogue firewall rule removed
$rule = Get-NetFirewallRule -DisplayName "Remote Desktop - Maintenance Access" -ErrorAction SilentlyContinue
if (-not $rule) {
    Write-Host "[OK] PASS: Rogue 'Remote Desktop - Maintenance Access' firewall rule removed. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: Rogue firewall rule still present."
}

# Check 3: AdminSDHolder ACE removed
$acl = dsacls.exe "CN=AdminSDHolder,CN=System,DC=corp,DC=local" 2>$null
if (($acl -join "`n") -notmatch "svc-reports") {
    Write-Host "[OK] PASS: AdminSDHolder no longer grants rights to svc-reports. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: AdminSDHolder still grants rights to svc-reports."
}

# Check 4: self-healing logon-script backdoor removed
Import-Module ActiveDirectory -ErrorAction SilentlyContinue
$scriptPath = (Get-ADUser -Identity jsmith -Properties scriptPath -ErrorAction SilentlyContinue).scriptPath
if (-not $scriptPath -or $scriptPath -ne "selfheal.bat") {
    Write-Host "[OK] PASS: jsmith's logon script backdoor has been cleared. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: jsmith's logon script is still set to the backdoor script."
}

# Check 5: disguised scheduled task removed
$task = Get-ScheduledTask -TaskPath "\Microsoft\Windows\UpdateOrchestratorEx\" -TaskName "USO_Svc_Refresh" -ErrorAction SilentlyContinue
if (-not $task) {
    Write-Host "[OK] PASS: Disguised USO_Svc_Refresh scheduled task removed. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: Disguised scheduled task still present."
}

# Check 6: AD DS still healthy
$ntds = Get-Service -Name NTDS -ErrorAction SilentlyContinue
if ($ntds -and $ntds.Status -eq "Running") {
    Write-Host "[OK] PASS: Active Directory Domain Services is running. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: Active Directory Domain Services is not running!"
}

# Check 7: DNS still healthy
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
