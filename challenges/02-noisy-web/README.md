# Challenge 02: The Noisy Web Server

**Category:** Service Hardening & Secure Configuration
**Difficulty:** Easy
**Time estimate:** 30 minutes
**Format:** Vagrant (Linux)

## Scenario
Welcome to WidgetCorp. You are the new IT Administrator. The previous admin left abruptly and set up a new Ubuntu web server, but we suspect they left it highly insecure. We have an audit in 30 minutes.

<details>
<summary><strong>Learning Objectives</strong> (spoiler — click to reveal)</summary>

- Enable and configure a host firewall (UFW) without locking yourself out
- Identify and disable an unnecessary/vulnerable network service
- Find and remove or lock an unauthorized local account
- Harden `sshd_config` against root login and empty-password authentication
- Fix a misconfigured system without taking down the service it's meant to protect

</details>

## Objectives
Secure the server without breaking the website.

## Prerequisites
Vagrant will automatically detect your computer's architecture. Please install the software required for your specific machine:

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
| **Start** | `vagrant up` (auto-installs Ansible in the VM and breaks it — a few minutes) |
| **SSH** | `vagrant ssh` |
| **Site** | http://192.168.56.10 (from the host) or http://localhost (from inside the VM) |

## Rules of Engagement
- **DO NOT** stop the Apache2 web service. It must remain online.
- You must enable the firewall (UFW) and block unauthorized ports.
- Find and remove/secure any weak accounts.
- Secure the SSH configuration.

<details>
<summary><strong>Hints</strong> (try without these first — click to reveal)</summary>

- `ufw status` / `ufw enable` — a default-deny inbound policy plus explicit allows for the ports you actually need is the simplest fix.
- `systemctl status vsftpd` — is an FTP server actually part of this box's job?
- `cat /etc/passwd` and `getent group sudo` — check for accounts that don't belong, especially ones with sudo rights.
- `/etc/ssh/sshd_config` — both root login and empty-password authentication should be explicitly disabled.

</details>

## Scoring
Run the scoring engine inside the VM: `sudo /vagrant/scripts/score_me.sh`

<details>
<summary>Scoring criteria (spoiler — click to reveal)</summary>

| Points | Criteria |
|---|---|
| +1 | UFW firewall is active |
| +1 | Vulnerable FTP service (`vsftpd`) is stopped |
| +1 | Apache web server is still online |
| +1 | Backdoor account (`backupadmin`) removed |
| +1 | SSH root login disabled |
| +1 | SSH empty-password authentication disabled |

> **Expected finding count: 4** *(FTP service, backdoor account, SSH root login, SSH empty passwords)*

</details>

## Pause and Resume
When you want to take a break, use `vagrant halt` to stop the VM and then `vagrant up` to resume your machine. It will save your progress.

## Cleanup
When you are finished practicing, run the following command in this directory to completely delete the virtual machine and free up your hard drive space:

`vagrant destroy -f`
