# Challenge 07: Web App Config Hardening

**Category:** Service Hardening & Secure Configuration
**Difficulty:** Medium
**Time estimate:** 40-60 minutes
**Format:** Vagrant (Linux)

## Scenario
WidgetCorp's internal app went from "works on my machine" to production without a second look: it runs as root under systemd, the default admin credential from the demo build is still live, and nginx is happily listing the app's source directory to anyone who asks.

## Learning Objectives
- Run an application under a dedicated unprivileged systemd user instead of root
- Find and rotate a default/demo credential before it ships
- Disable nginx directory listing (`autoindex`) on a sensitive path
- Make a config change and confirm the running service picked it up

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

## Hints *(try without these first)*
- `systemctl cat widgetapp` shows the unit file — add a `User=` line for a dedicated account and reload/restart.
- The app's credential store is a plain dict in `/opt/widgetapp/app.py` — change it and restart the service.
- `location /app/ { autoindex on; }` in the nginx site is what's exposing the listing — turn it off or remove the location block entirely.
- `nginx -t && systemctl reload nginx` applies a config change without downtime.

## Scoring
Run `sudo /vagrant/scripts/score_me.sh` inside the VM.

| Points | Criteria |
|---|---|
| +1 | `widgetapp` runs as a non-root user |
| +1 | Default admin credential no longer works |
| +1 | `/app/` directory listing disabled |
| +1 | Main app page still responds |

> **Expected finding count: 3** *(root-run service, default credential, directory listing)*
