# Challenge 12: Linux Persistence Hunt

**Category:** Persistence & Backdoor Hunting
**Difficulty:** Hard
**Time estimate:** 40-60 minutes
**Format:** Vagrant (Linux)

## Scenario
WidgetCorp's ops box runs a legitimate Apache site and not much else — or so the previous admin thought. An audit is coming up and you've been asked to sweep the box for anything that shouldn't be there before it happens.

## Learning Objectives
- Enumerate cron-based persistence for every user, not just the current one
- Identify a disguised systemd service by what it runs, not its unit name
- Audit `~/.ssh/authorized_keys` for unauthorized keys
- Recognize self-healing persistence delivered via shell profile scripts
- Find SUID-root binaries planted outside their expected locations
- Audit `/etc/sudoers.d/` for unauthorized privilege grants
- Remediate without breaking a running business service

## Objectives
- Find and remove all 6 persistence mechanisms
- Keep the Apache web server online throughout
- Document what you found (technique, artifact, how it was remediated)

## Connect
| Field | Value |
|---|---|
| **SSH To** | `vagrant ssh` (or 192.168.56.10) |
| **Username** | `vagrant` |
| **Password** | `vagrant` |

## Rules of Engagement
- Do not stop the Apache web service — it must remain online.
- Do not remove the legitimate `vagrant` account.

## Hints *(try without these first)*
- `crontab -l` (as root, via `sudo crontab -l`) — a job firing every minute is worth a second look.
- `systemctl list-unit-files --state=enabled` — check what actually runs, not just what the name implies.
- `cat ~/.ssh/authorized_keys` — is every key one you recognize?
- `/etc/profile.d/` scripts run on every interactive login — check what's in there.
- `find / -perm -4000 -type f 2>/dev/null` finds every SUID binary on the box; most of what you'll see is normal, one isn't.
- `ls /etc/sudoers.d/` and check each file's contents.

## Scoring
Run `sudo /vagrant/scripts/score_me.sh` inside the VM.

| Points | Criteria |
|---|---|
| +1 | Unauthorized root cron job removed |
| +1 | Rogue `systemd-networkd-helper` service removed |
| +1 | Unauthorized SSH key removed from `vagrant`'s `authorized_keys` |
| +1 | Backdoor account and its self-healing `/etc/profile.d/` script both removed |
| +1 | SUID-root shell backdoor removed |
| +1 | Unauthorized NOPASSWD sudoers entry removed |
| +1 | Apache web server still online |

> **Expected persistence count: 6**
