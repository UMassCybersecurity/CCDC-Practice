# Challenge 10 Answer Key — Rogue systemd Service

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's broken / planted
The image's `/entrypoint.sh` starts two things: the legitimate `/opt/monitoring-agent.sh` (writes a heartbeat to `/var/log/monitoring-agent.log` every 2s), and a loop that keeps `/opt/.sys/systemd-udevd-helper` running — a disguised script that writes "check-in" lines to `/var/log/.beacon` every 2s and gets relaunched by the entrypoint's watchdog loop within ~3s of being killed if the file still exists on disk.

## Step-by-step fix
1. `docker compose exec app bash`
2. `ps aux` — notice `systemd-udevd-helper` running from `/opt/.sys/`, an odd location for a real udev helper.
3. `rm -f /opt/.sys/systemd-udevd-helper` — remove the file **before** killing the process, so the entrypoint's watchdog loop has nothing left to relaunch.
4. `pkill -f systemd-udevd-helper` — stop the currently running instance.
5. Wait a few seconds, then `ps aux` again to confirm it doesn't come back, and check `/var/log/monitoring-agent.log` is still growing.
6. `exit`, then `docker compose exec app score_me.sh` to confirm a perfect score.

## Validation
Ran a fresh `docker compose up -d --build` on 2026-08-14, confirmed `score_me.sh` showed `1 / 3` (monitoring-agent fine, rogue process and its file both still present), then applied the steps above verbatim inside the running container (confirmed via `ps aux` that the watchdog loop really does respawn the process within a few seconds if the file isn't deleted first) and confirmed `3 / 3` after removing the file and killing the process. Torn down with `docker compose down -v` afterward.
