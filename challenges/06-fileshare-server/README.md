# Challenge 06: The File-Drop Server

**Category:** Service Hardening & Secure Configuration
**Difficulty:** Medium
**Time estimate:** 40-60 minutes
**Format:** Vagrant (Linux)
**Track:** Linux/Docker/SIEM

## Scenario
WidgetCorp's file-drop server hosts a shared directory for internal documents, fronted by an Apache default page for a status check. An audit is coming up, and a quick look at the box turned up a few things that don't look right.

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

## Scoring
Run `sudo /vagrant/scripts/score_me.sh` inside the VM.

<details>
<summary>Scoring criteria (spoiler — click to reveal)</summary>

| Points | Criteria |
|---|---|
| +1 | `/srv/fileshare` is no longer world-writable |
| +1 | SUID backdoor removed or de-fanged |
| +1 | `intern`'s passwordless sudo grant removed |
| +1 | Apache still online |

> **Expected finding count: 3** *(fileshare permissions, SUID backdoor, sudoers grant)*

</details>
