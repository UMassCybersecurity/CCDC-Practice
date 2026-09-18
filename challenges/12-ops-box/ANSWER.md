# Challenge 12 Answer Key — The Ops Box

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## Learning Objectives
- Enumerate cron-based persistence for every user, not just the current one
- Identify a disguised systemd service by what it runs, not its unit name
- Audit `~/.ssh/authorized_keys` for unauthorized keys
- Recognize self-healing persistence delivered via shell profile scripts
- Find SUID-root binaries planted outside their expected locations
- Audit `/etc/sudoers.d/` for unauthorized privilege grants
- Remediate without breaking a running business service

## Hints
- `crontab -l` (as root, via `sudo crontab -l`) — a job firing every minute is worth a second look.
- `systemctl list-unit-files --state=enabled` — check what actually runs, not just what the name implies.
- `cat ~/.ssh/authorized_keys` — is every key one you recognize?
- `/etc/profile.d/` scripts run on every interactive login — check what's in there.
- `find / -perm -4000 -type f 2>/dev/null` finds every SUID binary on the box; most of what you'll see is normal, one isn't.
- `ls /etc/sudoers.d/` and check each file's contents.

## Scoring breakdown
| Points | Criteria |
|---|---|
| +1 | Unauthorized root cron job removed |
| +1 | Rogue `systemd-networkd-helper` service removed |
| +1 | Unauthorized SSH key removed from `vagrant`'s `authorized_keys` |
| +1 | Backdoor account and its self-healing `/etc/profile.d/` script both removed |
| +1 | SUID-root shell backdoor removed |
| +1 | Unauthorized NOPASSWD sudoers entry removed |
| +1 | Apache web server still online |

## What's broken / planted
`scripts/plant-persistence.yml` (Ansible, run via `ansible_local` at `vagrant up`) plants:
1. Root crontab entry `* * * * * /usr/bin/id >> /tmp/.svc-cache 2>&1`.
2. `/etc/systemd/system/systemd-networkd-helper.service`, enabled and running, executing `/usr/local/lib/systemd-networkd-helper.sh` (a local check-in loop).
3. An unauthorized `ssh-ed25519` key (comment `svc-maint@corp`) appended to `/home/vagrant/.ssh/authorized_keys`.
4. A backdoor account `svc-tools` (password `C4che!2024`, in `sudo` group) plus `/etc/profile.d/99-cache-check.sh`, which recreates `svc-tools` on any interactive login if it's missing.
5. A SUID-root copy of `bash` at `/usr/local/bin/.sysbash`.
6. `/etc/sudoers.d/90-reports`, granting user `reports` `NOPASSWD:ALL`.

## Step-by-step fix
1. `vagrant ssh`
2. **Cron**: `sudo crontab -l -u root | grep -v '.svc-cache' | sudo crontab -u root -`
3. **Systemd service**: `sudo systemctl disable --now systemd-networkd-helper.service && sudo rm /etc/systemd/system/systemd-networkd-helper.service /usr/local/lib/systemd-networkd-helper.sh && sudo systemctl daemon-reload`
4. **SSH key**: `sudo sed -i '/svc-maint@corp/d' /home/vagrant/.ssh/authorized_keys`
5. **Self-healing account**: `sudo rm /etc/profile.d/99-cache-check.sh && sudo userdel -r svc-tools`
6. **SUID backdoor**: `sudo rm /usr/local/bin/.sysbash`
7. **Sudoers**: `sudo rm /etc/sudoers.d/90-reports`
8. Confirm Apache is still up: `curl -s http://localhost | grep "Apache2 Ubuntu Default Page"`
9. `sudo /vagrant/scripts/score_me.sh` to confirm a perfect score (7/7).

Order matters for step 5: remove the profile.d script *before* deleting the account, otherwise a login in between (including your own next `sudo` shell) could recreate it.

## Validation
Ran a fresh `vagrant up` on 2026-08-14, confirmed `score_me.sh` showed 1/7 before any fix, applied the steps above verbatim as root (in the stated order), and confirmed a perfect 7/7. Torn down with `vagrant destroy -f` afterward.
