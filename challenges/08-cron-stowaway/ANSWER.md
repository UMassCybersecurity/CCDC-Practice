# Challenge 08 Answer Key — Cron Stowaway

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's broken / planted
`scripts/setup.sh` (baked into the image at build time) plants two things in the `app` container's root crontab:
- A legitimate nightly backup entry: `0 2 * * * /usr/bin/date >> /var/log/backup.log` — must survive.
- An unauthorized entry: `* * * * * /usr/bin/whoami >> /tmp/.cache 2>&1` — fires every minute, must be removed.

It also appends a shell function to `/etc/bash.bashrc` that shadows `sudo`, logging every invocation to `/var/tmp/.sess` before calling through to the real `sudo` — must be removed.

## Step-by-step fix
1. `docker compose exec app bash`
2. `crontab -l` — confirm both the legit backup line and the per-minute `whoami` line are present.
3. `crontab -l | grep -v whoami | crontab -` — removes only the unauthorized line, leaves the backup job.
4. `grep -n 'training artifact' /etc/bash.bashrc` — locate the backdoor block.
5. `sed -i '/training artifact: logs sudo invocations/,/^}/d' /etc/bash.bashrc` — removes the whole planted block (comment through closing brace).
6. `exit` back to the host, then `docker compose exec app score_me.sh` to confirm a perfect score.

## Validation
Ran a fresh `docker compose up -d --build` on 2026-08-14, confirmed `score_me.sh` showed `0 / 3` (unauthorized cron present, backdoor present — note the legit-backup check also happened to fail once during initial authoring due to a `set -e`/subshell bug in `setup.sh`'s original crontab-append logic, which was fixed by switching to a single heredoc write), then applied the steps above verbatim inside the running container and confirmed `3 / 3`. Torn down with `docker compose down -v` afterward.
