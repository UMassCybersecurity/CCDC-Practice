# Challenge 02 Answer Key — The Noisy Web Server

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

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
