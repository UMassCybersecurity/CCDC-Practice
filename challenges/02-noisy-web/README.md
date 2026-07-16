# CCDC Beginner Scenario: The Noisy Web Server

## Situation Report
Welcome to WidgetCorp. You are the new IT Administrator. The previous admin left abruptly and setup a new Ubuntu Web Server, but we suspect they left it highly insecure. We have an audit in 30 minutes. 

**Your Objective:** Secure the server without breaking the website.

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

## How to Play
1. Open your terminal in this directory.
2. Run `vagrant up` to build and intentionally break the environment. *(Note: This will automatically install Ansible inside the VM and configure the broken state. This may take a few minutes.)*
3. Run `vagrant ssh` to log into the compromised server.
4. Secure the machine! 
5. When you think you are done, run the scoring engine inside the VM by typing: `sudo /vagrant/scripts/score_me.sh`

## Rules of Engagement
- **DO NOT** stop the Apache2 web service. It must remain online.
- You must enable the firewall (UFW) and block unauthorized ports.
- Find and remove/secure any weak accounts.
- Secure the SSH configuration.

## Pause and Resume
When you want to take a break, use `vagrant halt` to stop the VM and then `vagrant up` to resume your machine. It will save your progress.

## Cleanup
When you are finished practicing, run the following command in this directory to completely delete the virtual machine and free up your hard drive space:

`vagrant destroy -f`