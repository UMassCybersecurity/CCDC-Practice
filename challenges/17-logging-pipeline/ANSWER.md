# Challenge 17 Answer Key — The Logging Pipeline

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## Learning Objectives
- Recognize a logging pipeline that's been tampered with to create a blind spot
- Understand how rsyslog filtering/discard rules can selectively hide activity
- Use restored visibility (and direct system inspection) to find a hidden persistence mechanism

## Hints
- rsyslog reads config from `/etc/rsyslog.conf` and everything under `/etc/rsyslog.d/`.
- A `stop` in an rsyslog filter action drops the message entirely — it never reaches the log files.
- Once you know what's being hidden, `crontab -l -u <user>` for suspicious local accounts is a fast next step.

## Scoring breakdown
| Points | Criteria |
|---|---|
| +1 | rsyslog filter suppressing the hidden user's log lines is removed |
| +1 | rsyslog service still running (logging actually restored, not disabled) |
| +1 | Hidden persistence mechanism removed |
| +1 | Apache web server still online |

## What's planted
`scripts/plant-blindspot.yml` creates three local service accounts, each
with its own cron job, to make the rogue one blend in instead of being the
only account with a crontab:
- `svc-backup` — a legitimate nightly `tar` backup job (02:00).
- `svc-cleanup` — a legitimate hourly `/tmp` sweep (:15 past the hour).
- `svc-metrics` — the actual planted persistence: a per-minute job that
  appends a check-in line to `/tmp/.metrics_cache_heartbeat` (self-contained,
  no real network calls).

It also installs four legitimate rsyslog noise-reduction filters
(`05-discard-snapd.conf`, `06-discard-nm-dhcp.conf`,
`07-discard-systemd-user.conf`, `08-discard-chrony.conf`) alongside the one
that matters, `50-app-metrics-filter.conf`, which contains
`if $msg contains 'svc-metrics' then stop` — this silently drops any syslog
line mentioning `svc-metrics`, including the CRON log lines that would
otherwise reveal the per-minute job running. `scripts/seed-logs.sh` also
backdates a few days of plausible CRON/SSH/systemd noise directly into
`/var/log/syslog` and `/var/log/auth.log` (bypassing rsyslog entirely, so
none of it is subject to the filters) so the box doesn't boot with
suspiciously empty logs.

## Step-by-step fix
1. `vagrant ssh`
2. `sudo tail -50 /var/log/syslog` shows plenty of routine CRON/systemd/apt
   activity — but if you list crontabs for the service accounts
   (`sudo crontab -l -u svc-backup`, `-u svc-cleanup`, `-u svc-metrics`),
   `svc-metrics`'s per-minute job has **no matching CRON log lines at all**
   in syslog, unlike the other two accounts' jobs, which do show up. That
   gap — a crontab entry with zero corresponding log activity — is the tell,
   and it's genuinely easier to spot after restoring logging than by
   guessing which of three accounts to suspect.
3. `grep -r svc-metrics /etc/rsyslog.d/ /etc/rsyslog.conf` → finds
   `/etc/rsyslog.d/50-app-metrics-filter.conf` with the discard rule (the
   other four rsyslog.d filters are legitimate noise reduction — leave them).
4. Remove it and restart logging:
   ```bash
   sudo rm /etc/rsyslog.d/50-app-metrics-filter.conf
   sudo systemctl restart rsyslog
   ```
5. With logging restored, `sudo tail -f /var/log/syslog` now shows
   `svc-metrics`'s CRON line firing every minute — confirms the job and the
   fix. Remove the persistence:
   ```bash
   sudo crontab -r -u svc-metrics
   ```
   (Removing the `svc-metrics` account entirely, e.g.
   `sudo userdel -r svc-metrics`, is also an acceptable fix and scores the
   same.)
6. Confirm Apache is untouched: `curl http://localhost` still shows the
   default page.

## Validation
Ran a fresh `vagrant up` on 2026-08-14, confirmed `score_me.sh` showed 2/4 before any fix (the blind spot itself doesn't fail the "rsyslog running" check, only the filter/persistence checks), applied the steps above verbatim as root, and confirmed a perfect 4/4. Torn down with `vagrant destroy -f` afterward.

Re-validated on 2026-09-18 after reworking the challenge for realism: renamed
the account from the on-the-nose `mallory` to `svc-metrics`, added two more
legitimate service accounts with their own cron jobs, added four legitimate
rsyslog noise filters alongside the malicious one, and seeded a few days of
backdated CRON/SSH/systemd log history. Confirmed a fresh `vagrant up`
provisions cleanly, all three cron jobs and all five rsyslog.d filters exist
as expected, and `svc-metrics`'s CRON entries are genuinely absent from
`/var/log/syslog` while `svc-backup`'s and `svc-cleanup`'s appear normally.
Confirmed `score_me.sh` shows `2/4` on the unfixed box, applied the updated
steps above verbatim, confirmed a perfect `4/4`, and confirmed
`/var/log/syslog`/`/var/log/auth.log` each contain several hundred combined
lines of seeded history so the box no longer looks suspiciously empty. Torn
down with `vagrant destroy -f` afterward.
