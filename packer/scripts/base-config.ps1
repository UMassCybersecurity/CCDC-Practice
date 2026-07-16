# base-config.ps1

Write-Host "=== Configuring base Windows settings ==="

# Disable Windows Update
Set-Service -Name wuauserv -StartupType Disabled
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue

# Disable Server Manager at login
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager" `
    -Name "DoNotOpenServerManagerAtLogon" `
    -PropertyType DWORD `
    -Value 1 `
    -Force

# Enable RDP
Set-ItemProperty `
    -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
    -Name "fDenyTSConnections" `
    -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Set timezone
Set-TimeZone -Id "Eastern Standard Time"

# Ensure WinRM is configured
winrm quickconfig -force
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

Write-Host "=== Base configuration complete ==="
