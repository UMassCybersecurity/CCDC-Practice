# Challenge 02 Answer Key — The Noisy Web Server

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## Learning Objectives
- Enable and configure a host firewall (UFW) without locking yourself out
- Identify and disable an unnecessary/vulnerable network service
- Find and remove or lock an unauthorized local account
- Harden `sshd_config` against root login and empty-password authentication
- Fix a misconfigured system without taking down the service it's meant to protect

## Hints
- `ufw status` / `ufw enable` — a default-deny inbound policy plus explicit allows for the ports you actually need is the simplest fix.
- `systemctl status vsftpd` — is an FTP server actually part of this box's job?
- `cat /etc/passwd` and `getent group sudo` — check for accounts that don't belong, especially ones with sudo rights.
- `/etc/ssh/sshd_config` — both root login and empty-password authentication should be explicitly disabled.

## Scoring breakdown
| Points | Criteria |
|---|---|
| +1 | UFW firewall is active |
| +1 | Vulnerable FTP service (`vsftpd`) is stopped |
| +1 | Apache web server is still online |
| +1 | Backdoor account (`backupadmin`) removed |
| +1 | SSH root login disabled |
| +1 | SSH empty-password authentication disabled |

## What's broken / planted
`scripts/break_server.yml` plants: UFW disabled; `vsftpd` (FTP) installed and running, unrelated to this box's actual job; a backdoor account `backupadmin` (password `password123`) in the `sudo` group; and two SSH weaknesses in `/etc/ssh/sshd_config` — `PermitRootLogin yes` and `PermitEmptyPasswords yes`.

## Step-by-step fix
`vagrant ssh`, then as root (`sudo -i`):
1. **Firewall**: allow the ports this box legitimately needs, then enable UFW — order matters, or you'll lock yourself out of SSH:
   ```
   ufw allow OpenSSH
   ufw allow 80/tcp
   ufw enable
   ```
2. **FTP service**: `systemctl stop vsftpd && systemctl disable vsftpd`
3. **Backdoor account**: `deluser --remove-home backupadmin`
4. **SSH hardening**: edit `/etc/ssh/sshd_config`, set `PermitRootLogin no` and `PermitEmptyPasswords no`, then `systemctl restart ssh`
5. Confirm Apache is still serving: `curl -s http://localhost | grep "Apache2 Ubuntu Default Page"`
6. Run `sudo /vagrant/scripts/score_me.sh` to confirm a perfect score (6/6).

## Validation
Ran a fresh `vagrant up` on 2026-08-14, confirmed `score_me.sh` showed 1/6 before any fix, applied the steps above verbatim as root, and confirmed a perfect 6/6. Torn down with `vagrant destroy -f` afterward.

Two pre-existing bugs found and fixed while validating (both predate this session, not introduced by the retrofit):
- `scripts/score_me.sh` shipped without the executable bit, so the README's documented `sudo /vagrant/scripts/score_me.sh` invocation failed with "command not found." Fixed with `chmod +x`.
- The scorer never checked `PermitEmptyPasswords`, even though the Rules of Engagement say "secure the SSH configuration" and the break script plants both SSH weaknesses. Added a 6th check (`MAX_SCORE` 5 → 6) so the rubric actually covers everything that's planted, per this repo's requirement to keep the break script, README rubric, and answer key in lockstep.
