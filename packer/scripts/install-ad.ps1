# install-ad.ps1
# Installs Active Directory Domain Services and promotes to Domain Controller

Write-Host "=== Installing AD Domain Services ==="

# Fix: suppress progress bar that breaks in SSH sessions
$ProgressPreference = 'SilentlyContinue'

Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Verify it actually installed
if (-not (Get-WindowsFeature AD-Domain-Services).Installed) {
    Write-Host "Feature install via cmdlet failed. Trying DISM..."
    dism /online /enable-feature /featurename:ActiveDirectory-DomainServices /all /norestart
    dism /online /enable-feature /featurename:DirectoryServices-DomainController /all /norestart
}

Write-Host "=== Promoting to Domain Controller ==="

$securePassword = ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force

Install-ADDSForest `
    -DomainName "corp.local" `
    -DomainNetBIOSName "CORP" `
    -SafeModeAdministratorPassword $securePassword `
    -InstallDns:$true `
    -NoRebootOnCompletion:$true `
    -Force:$true

Write-Host "=== AD DS installation complete. Reboot required. ==="
