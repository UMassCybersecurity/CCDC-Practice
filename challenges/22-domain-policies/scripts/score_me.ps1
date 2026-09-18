# score_me.ps1
# Challenge 22 - GPO Abuse - Scoring Engine
# Run this inside the VM as Administrator: C:\vagrant\scripts\score_me.ps1

$Score = 0
$MaxScore = 3

Write-Host "========================================"
Write-Host " GPO Abuse Scoring Engine v1.0"
Write-Host "========================================"
Write-Host ""

Import-Module GroupPolicy -ErrorAction SilentlyContinue

# Check 1: rogue GPO removed or unlinked
$rogue = Get-GPO -Name "Workstation Compliance Baseline" -ErrorAction SilentlyContinue
$stillLinked = $false
if ($rogue) {
    $report = [xml](Get-GPOReport -Guid $rogue.Id -ReportType Xml)
    $stillLinked = $report.GPO.LinksTo -ne $null
}
if (-not $rogue -or -not $stillLinked) {
    Write-Host "[OK] PASS: Rogue 'Workstation Compliance Baseline' GPO deleted or unlinked. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: Rogue 'Workstation Compliance Baseline' GPO is still linked."
}

# Check 2: its SYSVOL ScheduledTasks.xml payload removed
$found = Get-ChildItem -Path "C:\Windows\SYSVOL\domain\Policies" -Recurse -Filter "ScheduledTasks.xml" -ErrorAction SilentlyContinue |
    Where-Object { (Get-Content $_.FullName -Raw) -match "WindowsHealthCheck" }
if (-not $found) {
    Write-Host "[OK] PASS: Rogue GPP ScheduledTasks.xml removed from SYSVOL. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: Rogue GPP ScheduledTasks.xml payload still present in SYSVOL."
}

# Check 3: decoy GPOs left untouched
$decoys = @("Desktop Wallpaper Standard", "Screen Lock Timeout Policy", "Browser Homepage Configuration")
$missing = $decoys | Where-Object { -not (Get-GPO -Name $_ -ErrorAction SilentlyContinue) }
if ($missing.Count -eq 0) {
    Write-Host "[OK] PASS: All 3 legitimate decoy GPOs are still present. (+1)"
    $Score++
} else {
    Write-Host "[X] FAIL: One or more legitimate GPOs were removed: $($missing -join ', ')"
}

Write-Host ""
Write-Host "========================================"
Write-Host " FINAL SCORE: $Score / $MaxScore"
Write-Host "========================================"
