# Challenge 06: File Permissions Audit

**Category:** Service Hardening & Secure Configuration
**Difficulty:** Medium
**Time estimate:** 40-60 minutes
**Format:** Vagrant (Linux)

## Scenario
WidgetCorp's file-drop server hosts a shared directory for internal documents, fronted by an Apache default page for a status check. An audit turned up sloppy permissions across the box — a world-writable share, a low-privileged account with unrestricted sudo, and something that looks like a privilege-escalation backdoor hiding in `/usr/local/bin`.

## Learning Objectives
- Audit and correct world-writable directories and files
- Find and remove SUID-root privilege-escalation backdoors
- Identify and revoke unwarranted passwordless sudo grants
- Fix a misconfigured system without taking down a running service

## Objectives
- Lock down `/srv/fileshare` so it's no longer world-writable
- Find and remove the SUID-root backdoor binary
- Remove `intern`'s passwordless sudo grant
- Keep Apache online throughout

## Connect
| Field | Value |
|---|---|
| **Start** | `vagrant up` (first run provisions via Ansible, ~2-5 min) |
| **SSH** | `vagrant ssh` |
| **IP** | 192.168.56.10 |

## Rules of Engagement
- Do not stop the Apache web service — it must stay reachable on port 80.
- Don't delete the legitimate files in `/srv/fileshare`, just fix their permissions.

## Hints *(try without these first)*
- `find / -perm -4000 -type f 2>/dev/null` finds every SUID binary on the box — most of them are legitimate.
- Check `/etc/sudoers.d/` for anything granting `NOPASSWD:ALL` to an account that shouldn't have it.
- `chmod` the share to something that isn't world-writable — owner/group access is enough for a legitimate file-drop.
- `ls -la /usr/local/bin` — nothing legitimate normally lives there with a leading dot.

## Scoring
Run `sudo /vagrant/scripts/score_me.sh` inside the VM.

| Points | Criteria |
|---|---|
| +1 | `/srv/fileshare` is no longer world-writable |
| +1 | SUID backdoor removed or de-fanged |
| +1 | `intern`'s passwordless sudo grant removed |
| +1 | Apache still online |

> **Expected finding count: 3** *(fileshare permissions, SUID backdoor, sudoers grant)*
