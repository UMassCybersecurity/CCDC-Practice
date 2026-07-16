# shared/base.rb
# Common configuration for all CCDC training challenges
# Loaded by each challenge's Vagrantfile via require_relative
BOX_NAME = "ccdc/dc-base"
PACKER_DIR = File.expand_path("../../packer", __FILE__)
BOX_FILE = "#{PACKER_DIR}/output/package.box"
def apply_base_config(config)
 config.vm.box = BOX_NAME
 config.vm.guest = :windows
 config.vm.communicator = "winrm"
 # WinRM connection settings
 config.winrm.username = "vagrant"
 config.winrm.password = "vagrant"
 config.winrm.timeout = 300
 config.winrm.retry_limit = 20
 # Network
 config.vm.network "private_network", ip: "192.168.56.10"
 config.vm.network "forwarded_port", guest: 3389, host: 3389, id: "rdp", auto_correct: true
 # Provider settings
 config.vm.provider "virtualbox" do |v|
 v.memory = 4096
 v.cpus = 2
 v.gui = false
 v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
 v.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
 end
 # Auto-build trigger: builds the Packer box if it doesn't exist
 config.trigger.before :up do |trigger|
 trigger.name = "Ensure base box exists"
 trigger.ruby do |env, machine|
 unless system("vagrant box list | grep -q '#{BOX_NAME}'")
 puts ""
 puts "========================================================"
 puts " Base box '#{BOX_NAME}' not found."
 puts " Building with Packer. This only happens once."
 puts " Estimated time: ~20-30 minutes."
 puts " Go grab coffee."
 puts "========================================================"
 puts ""
 Dir.chdir(PACKER_DIR) do
 unless system("packer init .")
 abort "ERROR: 'packer init' failed. Is Packer installed?"
 end
 unless system("packer build .")
 abort "ERROR: Packer build failed. Check output above."
 end
 end
 unless system("vagrant box add #{BOX_NAME} #{BOX_FILE}")
 abort "ERROR: Failed to add box. Check that #{BOX_FILE} exists."
 end
 puts ""
 puts "========================================================"
 puts " Base box built successfully!"
 puts " Future 'vagrant up' commands will be fast (~2 min)."
 puts "========================================================"
 puts ""
 end
 end
 end
end
# Helper: add a Linux VM to a multi-machine challenge
def add_linux_vm(config, name, ip, memory, script)
 config.vm.define name do |machine|
 machine.vm.box = "ubuntu/jammy64"
 machine.vm.hostname = name
 machine.vm.network "private_network", ip: ip
 machine.vm.provider "virtualbox" do |v|
 v.memory = memory
 v.cpus = 1
 v.gui = false
 end
 machine.vm.provision "shell", path: script
 end
end
