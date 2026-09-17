# plant-backdoors.ps1
# Plants Kerberos-related credential-exposure issues on the corp.local DC.
# DO NOT READ THIS FILE BEFORE ATTEMPTING THE CHALLENGE

Write-Host "=== Setting up challenge scenario ==="

$ProgressPreference = 'SilentlyContinue'
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

Start-Sleep -Seconds 30

# --- 1. Kerberoastable service account ---
New-ADUser `
    -Name "svc-sql" `
    -SamAccountName "svc-sql" `
    -Path "CN=Users,DC=corp,DC=local" `
    -AccountPassword (ConvertTo-SecureString "SqlService2019" -AsPlainText -Force) `
    -Enabled $true `
    -PasswordNeverExpires $true `
    -Description "SQL Server service account"
setspn.exe -A MSSQLSvc/db01.corp.local:1433 svc-sql | Out-Null

# --- 2. AS-REP roastable account ---
New-ADUser `
    -Name "svc-legacy" `
    -SamAccountName "svc-legacy" `
    -Path "CN=Users,DC=corp,DC=local" `
    -AccountPassword (ConvertTo-SecureString "LegacyApp!2018" -AsPlainText -Force) `
    -Enabled $true `
    -PasswordNeverExpires $true `
    -Description "Legacy application account - predates Kerberos pre-auth rollout"
Set-ADAccountControl -Identity "svc-legacy" -DoesNotRequirePreAuth $true

# --- 3. GPP cpassword exposure in SYSVOL ---
# Encrypts a real plaintext with the publicly-documented default GPP AES key
# (disclosed in MS14-025 / MS15-014), matching how a real leftover
# Group Policy Preferences credential would look to a candidate who finds it.
function Protect-GppPassword {
    param([string]$Password)
    $key = [byte[]](0x4e,0x99,0x06,0xe8,0xfc,0xb6,0x6c,0xc9,0xfa,0xf4,0x93,0x10,0x62,0x0f,0xfe,0xe8,0xf4,0x96,0xe8,0x06,0xcc,0x05,0x79,0x90,0x20,0x9b,0x09,0xa4,0x33,0xb6,0x6c,0x1b)
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $key
    $aes.IV = New-Object byte[] 16
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $encryptor = $aes.CreateEncryptor()
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($Password)
    $encrypted = $encryptor.TransformFinalBlock($bytes, 0, $bytes.Length)
    return [Convert]::ToBase64String($encrypted).TrimEnd('=').Replace('+','-').Replace('/','_')
}

$cpassword = Protect-GppPassword -Password "LegacyAdmin2019!"
$gpo = New-GPO -Name "Legacy Workstation Defaults"
$sysvolPath = "C:\Windows\SYSVOL\domain\Policies\{$($gpo.Id)}\Machine\Preferences\Groups"
New-Item -Path $sysvolPath -ItemType Directory -Force | Out-Null
$groupsXml = @"
<?xml version="1.0" encoding="utf-8"?>
<Groups clsid="{3125E937-EB16-4b4c-9934-544FC6D24D26}">
	<User clsid="{DF5F1855-51E5-4d24-8B1A-D9BDE98BA1D1}" name="LegacyAdmin" image="2" changed="2019-03-14 10:22:31" uid="{12345678-1234-1234-1234-123456789012}">
		<Properties action="U" newName="" fullName="" description="Legacy local admin push" cpassword="$cpassword" changeLogon="0" noChange="1" neverExpires="1" acctDisabled="0" userName="LegacyAdmin"/>
	</User>
</Groups>
"@
Set-Content -Path "$sysvolPath\Groups.xml" -Value $groupsXml

Write-Host "=== Challenge scenario ready ==="
Write-Host "Kerberos/credential issues planted: 3"
