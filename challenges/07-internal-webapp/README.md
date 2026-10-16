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

## Prerequisites
Vagrant will automatically detect your computer's architecture. Please install the software required for your specific machine (full details in the [main README](../../README.md#prerequisites)):

**For Windows, Linux, and Intel-based Macs (x86):**
1. Install [VirtualBox](https://www.virtualbox.org/).
2. Install [Vagrant](https://www.vagrantup.com/).

**For Apple Silicon Macs (M1/M2/M3/M4):**
*(VirtualBox does not work on Apple Silicon. You must use VMware).*
1. Install [VMware Fusion](https://knowledge.broadcom.com/external/article/315638/download-and-install-vmware-fusion.html) (Free for personal use).
2. Install [Vagrant](https://www.vagrantup.com/).
3. Install the [Vagrant VMware Utility](https://developer.hashicorp.com/vagrant/docs/providers/vmware/vagrant-vmware-utility). Download the macOS version, open the file, and run the standard installer.
4. Finally, link Vagrant to VMware by running this single command in your Mac terminal:
   `vagrant plugin install vagrant-vmware-desktop`

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
