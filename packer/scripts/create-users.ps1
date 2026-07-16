# create-users.ps1
# Populates the domain with realistic users, groups, and OUs
Write-Host "=== Populating Active Directory ==="

$ProgressPreference = 'SilentlyContinue'

Import-Module ActiveDirectory

# Wait for AD to be fully ready after reboot
Write-Host "Waiting for AD to be ready (this may take a while)"
$maxRetries = 60
$retry = 0
while ($retry -lt $maxRetries) {
    try {
        Get-ADDomain -ErrorAction Stop
        Write-Host "AD is ready"
        break
    } catch {
        $retry++
        Write-Host "Waiting for AD to be ready... ($retry/$maxRetries)"
        Start-Sleep -Seconds 10
    }
}

# --- Organizational Units ---
Write-Host "Creating OUs..."
New-ADOrganizationalUnit -Name "Employees" -Path "DC=corp,DC=local"
New-ADOrganizationalUnit -Name "IT Department" `
    -Path "OU=Employees,DC=corp,DC=local"
New-ADOrganizationalUnit -Name "Management" `
    -Path "OU=Employees,DC=corp,DC=local"
New-ADOrganizationalUnit -Name "Service Accounts" -Path "DC=corp,DC=local"
New-ADOrganizationalUnit -Name "Servers" -Path "DC=corp,DC=local"
New-ADOrganizationalUnit -Name "Workstations" -Path "DC=corp,DC=local"

# --- Groups ---
Write-Host "Creating groups..."
New-ADGroup -Name "IT Admins" -GroupScope Global `
    -Path "OU=IT Department,OU=Employees,DC=corp,DC=local"
New-ADGroup -Name "Help Desk" -GroupScope Global `
    -Path "OU=IT Department,OU=Employees,DC=corp,DC=local"
New-ADGroup -Name "Managers" -GroupScope Global `
    -Path "OU=Management,OU=Employees,DC=corp,DC=local"
New-ADGroup -Name "SQL Admins" -GroupScope Global `
    -Path "DC=corp,DC=local"

# --- IT Users ---
Write-Host "Creating users..."

$itOU = "OU=IT Department,OU=Employees,DC=corp,DC=local"

New-ADUser -Name "John Smith" `
    -SamAccountName "jsmith" `
    -UserPrincipalName "jsmith@corp.local" `
    -GivenName "John" `
    -Surname "Smith" `
    -Title "Systems Administrator" `
    -Path $itOU `
    -AccountPassword (ConvertTo-SecureString "Welcome1!" -AsPlainText -Force) `
    -Enabled $true `
    -ChangePasswordAtLogon $false

New-ADUser -Name "Maria Johnson" `
    -SamAccountName "mjohnson" `
    -UserPrincipalName "mjohnson@corp.local" `
    -GivenName "Maria" `
    -Surname "Johnson" `
    -Title "Network Engineer" `
    -Path $itOU `
    -AccountPassword (ConvertTo-SecureString "Spring2024!" -AsPlainText -Force) `
    -Enabled $true `
    -ChangePasswordAtLogon $false

New-ADUser -Name "Bob Williams" `
    -SamAccountName "bwilliams" `
    -UserPrincipalName "bwilliams@corp.local" `
    -GivenName "Bob" `
    -Surname "Williams" `
    -Title "Help Desk Analyst" `
    -Path $itOU `
    -AccountPassword (ConvertTo-SecureString "Password123!" -AsPlainText -Force) `
    -Enabled $true `
    -ChangePasswordAtLogon $false

New-ADUser -Name "Ana Garcia" `
    -SamAccountName "agarcia" `
    -UserPrincipalName "agarcia@corp.local" `
    -GivenName "Ana" `
    -Surname "Garcia" `
    -Title "Security Analyst" `
    -Path $itOU `
    -AccountPassword (ConvertTo-SecureString "Secure#2024" -AsPlainText -Force) `
    -Enabled $true `
    -ChangePasswordAtLogon $false

# --- Management Users ---
$mgmtOU = "OU=Management,OU=Employees,DC=corp,DC=local"

New-ADUser -Name "Carol Thompson" `
    -SamAccountName "cthompson" `
    -UserPrincipalName "cthompson@corp.local" `
    -GivenName "Carol" `
    -Surname "Thompson" `
    -Title "CTO" `
    -Path $mgmtOU `
    -AccountPassword (ConvertTo-SecureString "Executive1!" -AsPlainText -Force) `
    -Enabled $true `
    -ChangePasswordAtLogon $false

New-ADUser -Name "David Lee" `
    -SamAccountName "dlee" `
    -UserPrincipalName "dlee@corp.local" `
    -GivenName "David" `
    -Surname "Lee" `
    -Title "IT Director" `
    -Path $mgmtOU `
    -AccountPassword (ConvertTo-SecureString "Director2024!" -AsPlainText -Force) `
    -Enabled $true `
    -ChangePasswordAtLogon $false

# --- Service Accounts ---
$svcOU = "OU=Service Accounts,DC=corp,DC=local"

New-ADUser -Name "svc_sql" `
    -SamAccountName "svc_sql" `
    -Path $svcOU `
    -AccountPassword (ConvertTo-SecureString "SQLService2024!" -AsPlainText -Force) `
    -Enabled $true `
    -ChangePasswordAtLogon $false `
    -Description "SQL Server Service Account"

New-ADUser -Name "svc_backup" `
    -SamAccountName "svc_backup" `
    -Path $svcOU `
    -AccountPassword (ConvertTo-SecureString "Backup#Svc1" -AsPlainText -Force) `
    -Enabled $true `
    -ChangePasswordAtLogon $false `
    -Description "Backup Service Account"

New-ADUser -Name "svc_web" `
    -SamAccountName "svc_web" `
    -Path $svcOU `
    -AccountPassword (ConvertTo-SecureString "WebApp2024!" -AsPlainText -Force) `
    -Enabled $true `
    -ChangePasswordAtLogon $false `
    -Description "Web Application Service Account"

# --- Group Memberships ---
Write-Host "Configuring group memberships..."
Add-ADGroupMember -Identity "IT Admins" -Members "jsmith", "mjohnson"
Add-ADGroupMember -Identity "Help Desk" -Members "bwilliams"
Add-ADGroupMember -Identity "Managers" -Members "cthompson", "dlee"
Add-ADGroupMember -Identity "SQL Admins" -Members "svc_sql", "jsmith"
Add-ADGroupMember -Identity "Domain Admins" -Members "jsmith"

# --- SPNs (makes accounts Kerberoastable) ---
Set-ADUser -Identity "svc_sql" `
    -ServicePrincipalNames @{Add="MSSQLSvc/sql01.corp.local:1433"}
Set-ADUser -Identity "svc_web" `
    -ServicePrincipalNames @{Add="HTTP/web01.corp.local"}

# --- DNS Records ---
Write-Host "Creating DNS records..."
Add-DnsServerResourceRecordA -Name "web01" `
    -ZoneName "corp.local" `
    -IPv4Address "192.168.56.20"
Add-DnsServerResourceRecordA -Name "sql01" `
    -ZoneName "corp.local" `
    -IPv4Address "192.168.56.30"
Add-DnsServerResourceRecordA -Name "mail01" `
    -ZoneName "corp.local" `
    -IPv4Address "192.168.56.40"

Write-Host "=== Active Directory population complete ==="
Write-Host "Domain: corp.local"
Write-Host "Users created: 8"
Write-Host "OUs created: 6"
Write-Host "Groups created: 4"
