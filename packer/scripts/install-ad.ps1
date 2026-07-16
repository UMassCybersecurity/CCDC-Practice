# install-ad.ps1
# Installs Active Directory Domain Services and promotes to Domain Controller

Write-Host "=== Installing AD Domain Services ==="

Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

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
