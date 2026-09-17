# Challenge 18 Answer Key — Windows Artifact Hunt

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's planted
Four static evidence files baked into the image under `/evidence/` (see
`Dockerfile`, `evidence/`):

- `autoruns.csv` — mostly legitimate startup entries (OneDrive, Windows
  Defender NIS, NVIDIA, Realtek, GoogleUpdate). One malicious row: `Run` key
  entry `WinUpdateHelper` pointing at `C:\ProgramData\Microsoft\svchost.exe`
  — masquerading as `svchost.exe` but running out of `ProgramData`, not
  `System32`, and unsigned (`Publisher: (Not verified) Unknown`). This is a
  secondary IOC for scenario realism — it isn't part of the graded findings.
- `scheduled_tasks.txt` — several legitimate maintenance tasks (Windows
  Update, GoogleUpdate, Office SPP, OneDrive) plus one malicious task at
  `\Microsoft\Windows\SystemHealth\Telemetry`, blank `Author`, action is
  `powershell.exe -enc <base64>` (a `Net.WebClient` download-and-run
  one-liner), and a trigger that repeats every 30 minutes — far more
  frequent than any of the legitimate daily/weekly tasks nearby.
- `ifeo_registry.txt` — a `reg export` of the IFEO key with several
  legitimate compatibility-shim entries plus the classic sticky-keys
  backdoor: `sethc.exe`'s `Debugger` value set to
  `C:\Windows\System32\cmd.exe`. Any time `sethc.exe` would normally run
  (pressing Shift 5x at the login/lock screen, including over RDP before
  authentication), Windows launches the configured "debugger" instead — an
  unauthenticated SYSTEM-level `cmd.exe`.
- `security_events.csv` — a log slice with normal 4624/4672/4634
  logon/logoff noise, plus one 4688 process-creation event at `09:41:58`
  showing `cmd.exe` spawned with `sethc.exe` as its creator process
  (confirming the IFEO backdoor was actually triggered at the RDP login
  screen), immediately followed by a 4688 event where that `cmd.exe`
  launches the `svchost.exe` masquerade from `autoruns.csv` — tying all
  three artifacts into one incident.

## Step-by-step fix
1. `docker compose exec app bash`
2. `cat /evidence/ifeo_registry.txt` → the `sethc.exe` subkey with
   `Debugger`="C:\\Windows\\System32\\cmd.exe" stands out next to the benign
   `CompatibilityFlags`/`MitigationOptions` entries around it.
3. `grep -B5 'SystemHealth' /evidence/scheduled_tasks.txt` → the `Telemetry`
   task's blank `Author`, encoded PowerShell action, and 30-minute repeat
   interval mark it as the outlier among named, vendor-authored tasks.
4. `grep '09:4' /evidence/security_events.csv` → the 4688 event chain shows
   `sethc.exe` spawning `cmd.exe`, corroborating that the IFEO key was
   exploited, not just planted.
5. Write to `/root/findings.txt`:
   ```
   IFEO_TARGET: sethc.exe
   IFEO_DEBUGGER: C:\Windows\System32\cmd.exe
   TASK_NAME: \Microsoft\Windows\SystemHealth\Telemetry
   ```

## Validation
Ran `docker compose up -d --build` fresh, confirmed
`docker compose exec app /scripts/score_me.sh` reported `0 / 3` with no
`findings.txt` present. Then ran:
```
docker compose exec app sh -c 'cat > /root/findings.txt <<EOF
IFEO_TARGET: sethc.exe
IFEO_DEBUGGER: C:\Windows\System32\cmd.exe
TASK_NAME: \Microsoft\Windows\SystemHealth\Telemetry
EOF'
```
and confirmed `docker compose exec app /scripts/score_me.sh` reported
`3 / 3` (this caught `score_me.sh` using `grep -qx` on patterns containing
literal backslashes, which BRE misparses — fixed to `grep -qxF`). Torn down
with `docker compose down -v --rmi local` afterward.
