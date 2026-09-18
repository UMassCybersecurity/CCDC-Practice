# Challenge 16 Answer Key — Live Intrusion Detection

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## Learning Objectives
- Enumerate running processes and listening sockets on a live system (`ps`, `ss`)
- Distinguish a disguised persistence mechanism from legitimate system services by behavior, not just name
- Recognize planted red-herring "evidence" and verify findings independently instead of trusting them

## Hints
- `ps aux` and `ss -tlnp` together will show you what's actually running and listening — a legit-sounding name doesn't mean legit.
- `systemctl list-units --type=service` includes both real and rogue services; check what each one's `ExecStart` actually points to.
- A file left behind by "someone else" is not the same thing as evidence you've verified yourself.

## Scoring breakdown
| Points | Criteria |
|---|---|
| +1 | Rogue systemd service stopped and disabled |
| +1 | Rogue process/port no longer live |
| +1 | Findings correctly identify the process name and port |
| +1 | Apache web server still online |

## What's planted
`scripts/plant-intrusion.yml` drops `scripts/udevd-helper.sh` to
`/usr/lib/systemd/systemd-udevd-helper`, installs it as a systemd unit named
`systemd-udevd-helper.service` (enabled + started, so it survives reboot and
is live from the moment the trainee connects), and enables/starts it. The
script opens a local `nc` listener on port 4917 and beacons to itself every
15 seconds, logging check-ins to `/var/log/udevd-helper.log`. It's disguised
as a udev helper — real `systemd-udevd` exists, this is a lookalike name and
path. `/tmp/.compromise_evidence` is a deliberate decoy with fabricated,
irrelevant IOCs — it should not appear in the trainee's findings.

The same playbook also plants legitimate noise so the rogue service isn't
one of only two things running on the box: `fail2ban` and `cron` (real,
enabled services), a second real listener (`monitoring-agent.service`, a
`python3 -m http.server` on port 9256 serving fake node-exporter-style
metrics text — boring and legitimate, not part of the answer), two extra
local accounts (`deploy`, `jdoe`) with home dirs and plausible
`.bash_history`, two legitimate root cron jobs (a nightly backup marker and
a weekly apt cleanup), and two backdated days of ordinary
`syslog`/`auth.log` noise (routine CRON/apt/fail2ban/apache lines, and
`jdoe`/`deploy` SSH sessions with real `sudo` commands). None of this is
graded — `score_me.sh` only checks the `systemd-udevd-helper` unit/process/
port, the findings file, and Apache — it's purely there so `ps aux`/
`ss -tlnp`/`/etc/passwd`/the crontab aren't trivially down to "two things,
one of them is obviously wrong."

## Step-by-step fix
1. `vagrant ssh`
2. `sudo ss -tlnp` → shows a process listening on `4917`.
3. `ps aux | grep 4917` or `sudo lsof -i :4917` → resolves to
   `/usr/lib/systemd/systemd-udevd-helper`.
4. `systemctl status systemd-udevd-helper` → confirms it's a systemd-managed
   service, not the real `systemd-udevd`.
5. Stop and disable it, and remove its files:
   ```bash
   sudo systemctl stop systemd-udevd-helper
   sudo systemctl disable systemd-udevd-helper
   sudo rm /etc/systemd/system/systemd-udevd-helper.service
   sudo rm /usr/lib/systemd/systemd-udevd-helper
   sudo systemctl daemon-reload
   ```
6. Write to `/root/findings.txt`:
   ```
   PROCESS: systemd-udevd-helper
   PORT: 4917
   ```
7. Confirm Apache is untouched: `curl http://localhost` still shows the
   default page.

## Validation
Ran a fresh `vagrant up` on 2026-08-14, confirmed the rogue listener on port 4917 was live and `score_me.sh` showed 1/4 before any fix, applied the steps above verbatim as root, and confirmed a perfect 4/4. Torn down with `vagrant destroy -f` afterward.

Re-validated on 2026-09-18 after adding the legitimate noise described above. Confirmed a fresh `vagrant up` provisions cleanly: `fail2ban`/`cron`/`monitoring-agent`/`systemd-udevd-helper` all report `enabled`, `ss -tlnp` shows real listeners on 22/80/9256/4917, `deploy`/`jdoe` exist with home dirs and history, the two cron jobs are present, and both log files carry the backdated noise alongside real live activity. Confirmed `score_me.sh` still shows `1/4` on the unfixed box (only the Apache check passes), applied the same fix steps verbatim, wrote the same findings, and confirmed a perfect `4/4`. Torn down with `vagrant destroy -f` afterward.
