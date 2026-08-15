# Challenge 17 Answer Key — SIEM Blind Spot

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's planted
`scripts/plant-blindspot.yml` creates a local user `mallory`, gives it a
per-minute cron job that appends a check-in line to `/tmp/.mallory_beacon`
(self-contained persistence — no real network calls), and installs
`/etc/rsyslog.d/60-filter.conf` with `if $msg contains 'mallory' then stop`,
which silently drops any syslog line mentioning `mallory` — including the
CRON log lines that would otherwise reveal the job running.

## Step-by-step fix
1. `vagrant ssh`
2. Notice logs look thin for a box that should be generating regular CRON
   entries: `sudo tail -50 /var/log/syslog` shows no `mallory` activity at all.
3. `grep -r mallory /etc/rsyslog.d/ /etc/rsyslog.conf` → finds
   `/etc/rsyslog.d/60-filter.conf` with the discard rule.
4. Remove it and restart logging:
   ```bash
   sudo rm /etc/rsyslog.d/60-filter.conf
   sudo systemctl restart rsyslog
   ```
5. With logging restored (or just by checking directly), find the
   persistence: `sudo crontab -l -u mallory` shows the beacon job.
6. Remove it:
   ```bash
   sudo crontab -r -u mallory
   ```
   (Removing the `mallory` account entirely, e.g. `sudo userdel -r mallory`,
   is also an acceptable fix and scores the same.)
7. Confirm Apache is untouched: `curl http://localhost` still shows the
   default page.

## Validation
Ran a fresh `vagrant up` on 2026-08-14, confirmed `score_me.sh` showed 2/4 before any fix (the blind spot itself doesn't fail the "rsyslog running" check, only the filter/persistence checks), applied the steps above verbatim as root, and confirmed a perfect 4/4. Torn down with `vagrant destroy -f` afterward.
