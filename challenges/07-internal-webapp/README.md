# Challenge 07: The Internal Web App

**Category:** Service Hardening & Secure Configuration
**Difficulty:** Medium
**Time estimate:** 40-60 minutes
**Format:** Vagrant (Linux)
**Track:** Linux/Docker/SIEM

## Scenario
WidgetCorp's internal app went from "works on my machine" to production without a second look: it runs as root under systemd, the default admin credential from the demo build is still live, and nginx is happily listing the app's source directory to anyone who asks.

## Objectives
- `widgetapp` must run as a non-root user
- The default `admin`/`admin123` credential must no longer work
- `/app/` must no longer list directory contents
- The main app page must keep responding

## Connect
| Field | Value |
|---|---|
| **Start** | `vagrant up` (first run provisions via Ansible, ~2-5 min) |
| **SSH** | `vagrant ssh` |
| **IP** | 192.168.56.10 |
| **App** | http://192.168.56.10/ (from the host) or http://localhost/ (from inside the VM) |

## Rules of Engagement
- Keep the main app page (`/`) responding the whole time.

## Scoring
Run `sudo /vagrant/scripts/score_me.sh` inside the VM.

**4 points total.** Full breakdown is in ANSWER.md.
