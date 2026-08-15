# Challenge 12 Answer Key — Linux Persistence Hunt

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

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
