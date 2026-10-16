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
- Track down and remove any unauthorized privilege-escalation backdoor on the box
- Keep Apache online throughout

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

## Rules of Engagement
- Do not stop the Apache web service — it must stay reachable on port 80.
- Don't delete the legitimate files in `/srv/fileshare`, just fix their permissions.

## Scoring
Run `sudo /vagrant/scripts/score_me.sh` inside the VM.

**4 points total.** Full breakdown is in ANSWER.md.
