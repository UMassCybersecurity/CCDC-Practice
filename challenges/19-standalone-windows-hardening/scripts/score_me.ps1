# score_me.ps1
# Challenge 19 - Standalone Windows Hardening - Scoring Engine
# Run this inside the VM as Administrator: C:\vagrant\scripts\score_me.ps1

$Score = 0
$MaxScore = 5

Write-Host "========================================"
Write-Host " Standalone Windows Hardening Scoring Engine v1.0"
Write-Host "========================================"
Write-Host ""

# Check 1: rogue admin account removed/disabled
Import-Module ActiveDirectory -ErrorAction SilentlyContinue
$isAdmin = (Get-ADGroupMember -Identity "Administrators" -ErrorAction SilentlyContinue | Where-Object { $_.SamAccountName -eq "svc-support" }) -ne $null
$user = Get-ADUser -Identity "svc-support" -Properties Enabled -ErrorAction SilentlyContinue
if (-not $isAdmin -and (-not $user -or -not $user.Enabled)) {
    Write-Host "[OK] PASS: svc-support is no longer an enabled admin. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: svc-support still exists as an enabled administrator."
}

# Check 2: wide-open SMB share removed/locked down
$share = Get-SmbShare -Name "Shared" -ErrorAction SilentlyContinue
$everyoneAccess = $null
if ($share) {
    $everyoneAccess = Get-SmbShareAccess -Name "Shared" -ErrorAction SilentlyContinue | Where-Object { $_.AccountName -like "*Everyone*" -and $_.AccessRight -eq "Full" }
}
if (-not $share -or -not $everyoneAccess) {
    Write-Host "[OK] PASS: 'Shared' SMB share no longer grants Everyone Full Control. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: 'Shared' SMB share still grants Everyone Full Control."
}

# Check 3: Defender real-time protection re-enabled
$mp = Get-MpPreference -ErrorAction SilentlyContinue
if ($mp -and -not $mp.DisableRealtimeMonitoring) {
    Write-Host "[OK] PASS: Defender real-time protection is enabled. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: Defender real-time protection is still disabled."
}

# Check 4: unquoted service path fixed or service removed
$svc = Get-CimInstance -ClassName Win32_Service -Filter "Name='ContosoAgent'" -ErrorAction SilentlyContinue
$stillVulnerable = $false
if ($svc) {
    $path = $svc.PathName
    if ($path -notmatch '^"' -and $path -match ' ') {
        $stillVulnerable = $true
    }
}
if (-not $stillVulnerable) {
    Write-Host "[OK] PASS: ContosoAgent service path is quoted or the service was removed. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: ContosoAgent still has an unquoted service path with a space."
}

# Check 5: RDP NLA re-enabled
$tsSetting = Get-WmiObject -Class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'" -ErrorAction SilentlyContinue
if ($tsSetting -and $tsSetting.UserAuthenticationRequired -eq 1) {
    Write-Host "[OK] PASS: RDP Network Level Authentication is enabled. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: RDP Network Level Authentication is still disabled."
}

Write-Host ""
Write-Host "========================================"
Write-Host " FINAL SCORE: $Score / $MaxScore"
Write-Host "========================================"
