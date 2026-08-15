# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A collection of self-contained CCDC (Collegiate Cyber Defense Competition) training labs. Each challenge under `challenges/<NN-name>/` spins up a deliberately-vulnerable/compromised VM (or set of VMs/containers) via Vagrant, and the trainee's job is to find and fix the issues without breaking legitimate services. There is no application code to build — this is infrastructure-as-code (Vagrant/Packer/Ansible/PowerShell/Docker) for provisioning training environments.

Labs are self-hosted by a single trainee on their own machine, on their own time — there is no central lab server or shared infrastructure to provision against. Everything a challenge needs (base box, provisioning scripts, scoring) runs locally under `vagrant up`.

Labs vary widely in scope: some are bite-sized single-topic injects (e.g. "configure nginx behind HTTPS in a Docker container"), others are more involved multi-mechanism scenarios (e.g. `01-find-persistence`'s six planted persistence mechanisms on a full AD domain controller). Don't assume every challenge needs the full Vagrant+Packer+AD machinery — a lightweight challenge may just be a `docker-compose.yml` plus a README.

## Commands

Run from inside a specific challenge directory (`challenges/<NN-name>/`). VM-based (Vagrant) challenges:

```bash
vagrant up          # Build/boot the challenge VM (first run builds the Windows base box via Packer, ~20-30 min; later runs ~2-3 min)
vagrant rdp          # RDP into a Windows challenge (or connect a client to 192.168.56.10:3389)
vagrant ssh           # SSH into a Linux challenge
vagrant suspend / resume   # Pause/resume, preserving state
vagrant halt          # Stop cleanly (Linux challenges use this for pause/resume instead of suspend)
vagrant destroy -f    # Tear down and start over
```

Lightweight, container-based challenges skip Vagrant entirely and use plain `docker compose up` / `docker compose down` instead (see "Docker-based challenges" below) — check the challenge's README for the exact invocation since there's no shared convention file for these yet.

Rebuilding the shared Windows base box manually:
```bash
cd packer
packer init .
packer build .
vagrant box add ccdc/dc-base output/package.box --force
```
Or force a rebuild via Vagrant: `vagrant box remove ccdc/dc-base` then `vagrant up` in any Windows challenge (the `before :up` trigger in `shared/base.rb` detects the missing box and re-runs Packer automatically).

There are no lint/test/build commands beyond `vagrant up` itself and each challenge's own scoring script (e.g. `challenges/02-noisy-web/scripts/score_me.sh`, run inside the VM once a challenge is believed solved).

## Architecture

**Three challenge families, matched to how involved the scenario is:**

- **Windows/AD challenges** (e.g. `01-find-persistence`) share one Packer-built base box (`ccdc/dc-base`), a Server 2022 domain controller for `corp.local`, defined in `packer/dc-base.pkr.hcl` and built in three steps: `base-config.ps1` (WinRM/RDP/timezone) → `install-ad.ps1` (promote to DC) → reboot → `create-users.ps1` (seed users/groups/OUs). This box is cached locally as a Vagrant box and only rebuilt when missing. Each challenge's Vagrantfile then layers a challenge-specific PowerShell provisioner on top (e.g. `plant-backdoors.ps1`) to inject the compromise scenario into the shared base.
- **Linux VM challenges** (e.g. `02-noisy-web`) use a plain Ubuntu box (`bento/ubuntu-22.04`) with no shared base box — provisioning is done via `ansible_local` running a playbook (`scripts/break_server.yml`) that intentionally misconfigures the VM (weak accounts, disabled firewall, insecure SSH, etc). These support both VirtualBox (Intel) and VMware Fusion (Apple Silicon), auto-selected in the Vagrantfile via `RbConfig` host CPU detection.
- **Docker-based challenges** (no example checked in yet — e.g. an "put nginx behind HTTPS" inject) skip Vagrant/Packer/VirtualBox entirely: just a `docker-compose.yml` (plus any config/certs the scenario needs) and a README. Use these for narrow, single-topic injects that don't need a full VM or AD domain — much faster to spin up than the Vagrant path, and there's no shared base image to keep in sync.

Pick the lightest family that fits the scenario: reach for Docker first, fall back to a Linux VM if the challenge genuinely needs systemd services/firewall/SSH-level OS control, and only reach for the Windows/AD box when the challenge is specifically about Active Directory.

**`shared/base.rb`** is required by every Windows challenge Vagrantfile (`require_relative "../../shared/base"`) and centralizes: box name/path, WinRM connection settings, the static private network (`192.168.56.10`) and RDP port forward, VirtualBox provider defaults, and the auto-build-on-missing-box trigger. It also defines `add_linux_vm`, a helper for adding a secondary Linux VM into a multi-machine Windows-based challenge. Changes to shared VM settings (network, credentials, WinRM config) belong here, not duplicated per-challenge.

**Challenge scripts are the challenge.** The provisioning script for each challenge (e.g. `plant-backdoors.ps1`, `break_server.yml`) *is* the scenario definition — it plants the specific vulnerabilities/persistence mechanisms trainees must find. These files carry a `DO NOT READ BEFORE ATTEMPTING` warning; treat them as answer keys and avoid revealing their contents to a user working through a challenge unless asked directly to inspect/modify the challenge setup itself. Each challenge README documents the expected findings and a scoring rubric that should stay in sync with what the provisioning script actually plants.

**Every challenge must ship a validated answer/walkthrough.** This lives in its own file, separate from `README.md` (e.g. `challenges/<NN-name>/ANSWER.md` or `WALKTHROUGH.md`), and is not something a trainee is meant to open before attempting the lab. It should be a concrete, step-by-step solution — the actual commands/clicks that resolve every item in the challenge's scoring rubric — and the challenge author is expected to have personally run it against a fresh `vagrant up` to confirm it works, not just derive it by reading the provisioning script. When authoring or editing a challenge, keep three things in lockstep: the provisioning script (what's broken), the README scoring rubric (what's graded), and the answer file (how to fix it) — if one changes, check the other two.

**Adding a new challenge**: create `challenges/<NN-name>/README.md` and `ANSWER.md` plus whichever of the above families fits — `Vagrantfile` + `scripts/` for a VM-based challenge (`require_relative "../../shared/base"` and call `apply_base_config(config)` if it's Windows/AD), or `docker-compose.yml` (+ supporting config) for a lightweight one. Validate the answer file end-to-end against a fresh build before considering the challenge done.

## Credentials & network (Vagrant challenges)

| Role | Username | Password |
|---|---|---|
| Local Admin | `vagrant` | `vagrant` |
| Domain Admin | `CORP\Administrator` | `P@ssw0rd!` |

Static IP `192.168.56.10`, RDP forwarded on host port `3389`. These are training-lab-only defaults, not a security concern in this context. Docker-based challenges define their own credentials/ports per-challenge in their README since there's no shared compose base yet.
