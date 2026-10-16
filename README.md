# CCDC Training Lab

## Prerequisites

Challenges come in three formats (see the `**Format:**` line at the top of each challenge README). What you need to install depends on the format and on your machine:

| Format | Windows | Linux | Intel Mac | Apple Silicon Mac (M1–M4) |
|---|---|---|---|---|
| **Vagrant (Linux)** | VirtualBox | VirtualBox | VirtualBox | VMware Fusion |
| **Vagrant (Windows/AD)** | VirtualBox + Packer | VirtualBox + Packer | VirtualBox + Packer | ❌ Not supported |
| **Docker** | Docker Desktop | Docker Engine | Docker Desktop | Docker Desktop |

Vagrant (Linux) challenges detect your CPU architecture automatically and pick VirtualBox or VMware for you. The Windows/AD challenges run a Windows Server 2022 x86 VM, which can't run on Apple Silicon. Use an x86 machine (Windows, Linux, or Intel Mac) for those.

**Hardware:** At least 16 GB RAM (the Windows/AD VM alone takes 4 GB) and at least 60 GB free disk space.

### Setup: Windows (x86)
1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads).
2. Install [Vagrant](https://developer.hashicorp.com/vagrant/install).
3. *(Windows/AD challenges)* Install [Packer](https://developer.hashicorp.com/packer/install) and make sure `packer` is on your `PATH`.
4. *(Docker challenges)* Install [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/).
5. RDP is built in: `vagrant rdp` opens the Remote Desktop client (`mstsc`).

> If VirtualBox VMs fail to start or run very slowly, Hyper-V / WSL2 / Virtualization-Based Security may be holding the CPU's virtualization features. You can turn them off with `bcdedit /set hypervisorlaunchtype off` in an admin prompt (then reboot), but WSL2 and Docker Desktop stop working until you switch it back with `bcdedit /set hypervisorlaunchtype auto`.

### Setup: Linux (x86)
1. Install [VirtualBox](https://www.virtualbox.org/wiki/Linux_Downloads).
2. Install [Vagrant](https://developer.hashicorp.com/vagrant/install).
3. *(Windows/AD challenges)* Install [Packer](https://developer.hashicorp.com/packer/install).
4. *(Docker challenges)* Install [Docker Engine](https://docs.docker.com/engine/install/) and the Compose plugin.
5. *(Windows/AD challenges)* Install an RDP client such as Remmina or `xfreerdp`.

### Setup: Intel Mac (x86)
1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads).
2. Install [Vagrant](https://developer.hashicorp.com/vagrant/install).
3. *(Windows/AD challenges)* Install [Packer](https://developer.hashicorp.com/packer/install) (`brew tap hashicorp/tap && brew install hashicorp/tap/packer`).
4. *(Docker challenges)* Install [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/).
5. *(Windows/AD challenges)* Install Microsoft's **Windows App** (formerly Microsoft Remote Desktop) from the Mac App Store to RDP into the VM.

> On first install, macOS may block VirtualBox's kernel extension. Allow it under **System Settings → Privacy & Security**, then reboot.

### Setup: Apple Silicon Mac (M1/M2/M3/M4)
VirtualBox does not work on Apple Silicon, so you must use VMware. Only Vagrant (Linux) and Docker challenges are supported.

> ⚠️ **Windows/AD challenges can't run on Apple Silicon for now.** Their Windows Server 2022 base box is x86-only and builds on VirtualBox only. Use an x86 machine (Windows, Linux, or Intel Mac) for any challenge whose README says `**Format:** Vagrant (Windows/AD)` or `Vagrant (Windows)`.
1. Install [VMware Fusion](https://knowledge.broadcom.com/external/article/315638/download-and-install-vmware-fusion.html) (free).
2. Install [Vagrant](https://developer.hashicorp.com/vagrant/install).
3. Install the [Vagrant VMware Utility](https://developer.hashicorp.com/vagrant/docs/providers/vmware/vagrant-vmware-utility). Download the macOS version, open the file, and run the standard installer.
4. Link Vagrant to VMware by running this command in your Mac terminal:
   ```bash
   vagrant plugin install vagrant-vmware-desktop
   ```
5. *(Docker challenges)* Install [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/).

### Verify your setup
```bash
vagrant --version
vagrant plugin list      # Apple Silicon only: should list vagrant-vmware-desktop
packer --version         # Windows/AD challenges only
docker compose version   # Docker challenges only
```

---

## Quick Start

1. Clone this repo
2. `cd` into any challenge directory
3. Read the challenge's README.md for setup and challenge goals
4. Run `vagrant up` (or `docker compose up` for Docker challenges — check the README)
5. Windows/AD challenges only: the first run auto-builds the base box with Packer *(~20–30 min)*
6. Subsequent runs boot in *~2–3 minutes*

---

## Usage

```bash
cd challenges/01-domain-controller-incident

vagrant up          # Start the challenge
vagrant rdp         # Connect via RDP (or use your RDP client to 192.168.56.10)
vagrant suspend     # Pause (saves state, fast resume)
vagrant resume      # Resume from suspend
vagrant destroy -f  # Delete and start over
vagrant up          # Rebuild fresh
```

---

## Credentials

| Role | Username | Password |
|---|---|---|
| Local Admin | `vagrant` | `vagrant` |
| Domain Admin | `CORP\Administrator` | `P@ssw0rd!` |

| Setting | Value |
|---|---|
| RDP Port | `3389` |
| IP Address | `192.168.56.10` (DC) |

---

## Challenge Format

Each challenge directory contains:

| File/Folder | Description |
|---|---|
| `Vagrantfile` | Defines the environment |
| `README.md` | Objectives, hints, scoring criteria |
| `scripts/` | Challenge-specific setup scripts |

---

## Rebuilding the Base Box

If you need to rebuild the base box (e.g., after an update):

```bash
vagrant box remove ccdc/dc-base
cd challenges/any-challenge
vagrant up
# Packer will auto-rebuild
```

Or manually:

```bash
cd packer
packer init .
packer build .
vagrant box add ccdc/dc-base output/package.box --force
```

---

## Packaging Challenges for Distribution

To zip up a challenge for handing out (e.g. to screening candidates via Google Drive):

```bash
scripts/package-challenge.sh <challenge-dir-name> [--bundle candidate|instructor|both] [--offline] [--build-box]
```

| Flag | Purpose |
|---|---|
| `--bundle candidate\|instructor\|both` | Which bundle(s) to produce (default: `both`) |
| `--offline` | Docker challenges only: bakes the built image(s) into the candidate bundle via `docker save`, so candidates don't need registry access |
| `--build-box` | Windows/AD and Linux-VM (Vagrant) challenges only: runs `vagrant up` + `vagrant package` to produce a pre-provisioned `.box` for the candidate bundle, since the provisioning script itself is the answer key. Slow — run once per challenge before its candidate bundle can be built |

Output lands in `dist/` at the repo root (gitignored). Run with no args for full usage.
