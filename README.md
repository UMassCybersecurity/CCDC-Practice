CCDC Training Lab
Prerequisites:
 - VirtualBox (https://www.virtualbox.org/wiki/Downloads)
 - Vagrant (https://www.vagrantup.com/downloads)
 - Packer (https://www.packer.io/downloads)
 - At least 16GB RAM recommended
 - At least 60GB free disk space
Quick Start:
 1. Clone this repo
 2. cd into any challenge directory
 3. Run: vagrant up
 4. First run will auto-build the base box with Packer (~20-30 min)
 5. Subsequent runs boot in ~2-3 minutes
Usage:
 `cd challenges/01-find-persistence`
 `vagrant up` Start the challenge
 `vagrant rdp` Connect via RDP (or use your RDP client to 192.168.56.10)
 `vagrant suspend` Pause (saves state, fast resume)
 `vagrant resume` Resume from suspend
 `vagrant destroy -f` Delete and start over
 `vagrant up` Rebuild fresh
Credentials:
 Local Admin: vagrant / vagrant
 Domain Admin: CORP\Administrator / P@ssw0rd!
 RDP Port: 3389
 IP Address: 192.168.56.10 (DC)
Challenge Format:
 Each challenge directory contains:
 - Vagrantfile Defines the environment
 - README.md Objectives, hints, scoring criteria
 - scripts/ Challenge-specific setup scripts
Rebuilding the Base Box:
 If you need to rebuild the base box (e.g., after an update):
 ```
 vagrant box remove ccdc/dc-base
 cd challenges/any-challenge
 vagrant up
 ```
 (Packer will auto-rebuild)
 Or manually:
 ```
 cd packer
 packer init .
 packer build .
 vagrant box add ccdc/dc-base output/package.box --force
 ```
