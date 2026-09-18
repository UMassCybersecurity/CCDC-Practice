# Challenge 06 Answer Key — The File-Drop Server

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## Learning Objectives
- Audit and correct world-writable directories and files
- Find and remove SUID-root privilege-escalation backdoors
- Identify and revoke unwarranted passwordless sudo grants
- Fix a misconfigured system without taking down a running service

## Hints
- `find / -perm -4000 -type f 2>/dev/null` finds every SUID binary on the box — most of them are legitimate.
- Check `/etc/sudoers.d/` for anything granting `NOPASSWD:ALL` to an account that shouldn't have it.
- `chmod` the share to something that isn't world-writable — owner/group access is enough for a legitimate file-drop.
- `ls -la /usr/local/bin` — nothing legitimate normally lives there with a leading dot.

## What's broken / planted
`scripts/break_server.yml` plants three issues: `/srv/fileshare` (and the files in it) created mode 0777/0666; `/etc/sudoers.d/90-intern` grants the `intern` account `NOPASSWD:ALL`; and `/usr/local/bin/.syshelper` is a copy of `/bin/bash` with the SUID bit set (`chmod 4755`), giving anyone who can execute it a root shell.

## Step-by-step fix
SSH in with `vagrant ssh`, then as root (`sudo -i`):
1. Fix the share's permissions: `chmod 750 /srv/fileshare && chmod 640 /srv/fileshare/*` (or any mode that drops the world-write bit — group ownership via the pre-existing `fileshare` group is fine too).
2. Remove the SUID backdoor: `rm -f /usr/local/bin/.syshelper` (or `chmod -s /usr/local/bin/.syshelper` to strip the SUID bit if you'd rather keep the file for evidence).
3. Remove the sudo grant: `rm -f /etc/sudoers.d/90-intern`.
4. Confirm Apache is still serving: `curl -s http://localhost | grep "Apache2 Ubuntu Default Page"`.

## Validation
Ran a fresh `vagrant up` on 2026-08-14, confirmed `score_me.sh` showed 1/4 before any fix, applied the steps above verbatim as root, and confirmed a perfect 4/4. Torn down with `vagrant destroy -f` afterward. Note: `scripts/score_me.sh` was shipped without the executable bit, which broke the README's documented `sudo /vagrant/scripts/score_me.sh` invocation with "command not found" — fixed at the source (`chmod +x`).
