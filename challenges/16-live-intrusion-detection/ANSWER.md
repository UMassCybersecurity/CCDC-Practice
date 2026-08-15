# Challenge 16 Answer Key — Live Intrusion Detection

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

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
