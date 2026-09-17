# plant-backdoors.ps1
# Plants local (non-AD-specific) hardening issues on the box
# DO NOT READ THIS FILE BEFORE ATTEMPTING THE CHALLENGE

Write-Host "=== Setting up challenge scenario ==="

$ProgressPreference = 'SilentlyContinue'
Import-Module ActiveDirectory

Start-Sleep -Seconds 30

# --- 1. Second admin account with a weak password ---
# (This box's OS has no real local SAM — New-LocalUser silently redirects to
# AD here — so this is planted directly as an AD account added to the
# server's own Administrators group, same practical effect.)
New-ADUser `
    -Name "svc-support" `
    -SamAccountName "svc-support" `
    -Path "CN=Users,DC=corp,DC=local" `
    -AccountPassword (ConvertTo-SecureString "Password1" -AsPlainText -Force) `
    -Enabled $true `
    -PasswordNeverExpires $true `
    -Description "Legacy helpdesk support account"
Add-ADGroupMember -Identity "Administrators" -Members "svc-support"

# --- 2. Wide-open SMB share ---
New-Item -Path "C:\Shared" -ItemType Directory -Force | Out-Null
Set-Content -Path "C:\Shared\notice.txt" -Value "Team file drop - temporary"
icacls "C:\Shared" /grant "Everyone:(OI)(CI)F" | Out-Null
New-SmbShare -Name "Shared" -Path "C:\Shared" -FullAccess "Everyone" -ErrorAction SilentlyContinue | Out-Null

# --- 3. Windows Defender real-time protection disabled ---
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue

# --- 4. Unquoted service path ---
$svcDir = "C:\Program Files\Contoso Agent"
New-Item -Path $svcDir -ItemType Directory -Force | Out-Null
Copy-Item "C:\Windows\System32\cmd.exe" "$svcDir\agent.exe" -Force
sc.exe create "ContosoAgent" binPath= "C:\Program Files\Contoso Agent\agent.exe" start= demand DisplayName= "Contoso Remote Agent" | Out-Null

# --- 5. RDP Network Level Authentication disabled ---
$tsSetting = Get-WmiObject -Class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'"
$tsSetting.SetUserAuthenticationRequired(0) | Out-Null

Write-Host "=== Challenge scenario ready ==="
Write-Host "Hardening issues planted: 5"
