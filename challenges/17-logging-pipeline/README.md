# Challenge 17: The Logging Pipeline

**Category:** Log & Traffic Analysis / Detection
**Difficulty:** Medium
**Time estimate:** 40-60 minutes
**Format:** Vagrant (Linux)
**Track:** Linux/Docker/SIEM

## Scenario
`prod-app04`'s logs look clean — suspiciously clean. Someone tampered with
the logging pipeline before you got here, and whatever they were hiding is
still running. You need to restore visibility first, then use it to find
what's actually going on.

## Objectives
- Find and remove whatever is suppressing log visibility, and get logging working normally again
- Find and remove the persistence mechanism that suppression was hiding
- Keep the Apache web service online throughout

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
| **Start** | `vagrant up` |
| **Connect** | `vagrant ssh` |
| **IP** | `192.168.56.10` |

## Rules of Engagement
- **DO NOT** stop the Apache2 web service. It must remain online.
- **DO NOT** just disable rsyslog entirely to "fix" the blind spot — that trades one blind spot for a bigger one. Fix the actual filter.

## Scoring
Inside the VM: `sudo /vagrant/scripts/score_me.sh`

**4 points total.** Full breakdown is in ANSWER.md.
