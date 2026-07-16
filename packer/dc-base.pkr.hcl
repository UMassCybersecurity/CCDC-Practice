packer {
 required_plugins {
 vagrant = {
 version = ">= 1.1.0"
 source = "github.com/hashicorp/vagrant"
 }
 }
}
source "vagrant" "windows-dc" {
  communicator = "ssh"
  source_path  = "gusztavvargadr/windows-server-2022-standard"
  provider     = "virtualbox"
  add_force    = true

  ssh_username = "vagrant"
  ssh_password = "vagrant"
  ssh_timeout  = "30m"
}
build {
 sources = ["source.vagrant.windows-dc"]
 # Step 1: Base configuration (enable features, set up WinRM properly)
 provisioner "powershell" {
 script = "scripts/base-config.ps1"
 }
 # Step 2: Install Active Directory Domain Services and promote to DC
 provisioner "powershell" {
 script = "scripts/install-ad.ps1"
 }
 # Step 3: Reboot after domain promotion
 provisioner "windows-restart" {
 restart_timeout = "15m"
 }
 # Step 4: Populate the domain with users, groups, OUs
 provisioner "powershell" {
 script = "scripts/create-users.ps1"
 }
}
