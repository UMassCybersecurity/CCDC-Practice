# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A collection of self-contained CCDC (Collegiate Cyber Defense Competition) training labs. Each challenge under `challenges/<NN-name>/` spins up a deliberately-vulnerable/compromised VM (or set of VMs/containers) via Vagrant, and the trainee's job is to find and fix the issues without breaking legitimate services. There is no application code to build — this is infrastructure-as-code (Vagrant/Packer/Ansible/PowerShell/Docker) for provisioning training environments.

Labs are self-hosted by a single trainee on their own machine, on their own time — there is no central lab server or shared infrastructure to provision against. Everything a challenge needs (base box, provisioning scripts, scoring) runs locally under `vagrant up`.

Labs vary widely in scope: some are bite-sized single-topic injects (e.g. "configure nginx behind HTTPS in a Docker container"), others are more involved multi-mechanism scenarios (e.g. `01-domain-controller-incident`'s six planted persistence mechanisms on a full AD domain controller). Don't assume every challenge needs the full Vagrant+Packer+AD machinery — a lightweight challenge may just be a `docker-compose.yml` plus a README.

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

- **Windows/AD challenges** (e.g. `01-domain-controller-incident`) share one Packer-built base box (`ccdc/dc-base`), a Server 2022 domain controller for `corp.local`, defined in `packer/dc-base.pkr.hcl` and built in three steps: `base-config.ps1` (WinRM/RDP/timezone) → `install-ad.ps1` (promote to DC) → reboot → `create-users.ps1` (seed users/groups/OUs). This box is cached locally as a Vagrant box and only rebuilt when missing. Each challenge's Vagrantfile then layers a challenge-specific PowerShell provisioner on top (e.g. `plant-backdoors.ps1`) to inject the compromise scenario into the shared base.
- **Linux VM challenges** (e.g. `02-noisy-web`) use a plain Ubuntu box (`bento/ubuntu-22.04`) with no shared base box — provisioning is done via `ansible_local` running a playbook (`scripts/break_server.yml`) that intentionally misconfigures the VM (weak accounts, disabled firewall, insecure SSH, etc). These support both VirtualBox (Intel) and VMware Fusion (Apple Silicon), auto-selected in the Vagrantfile via `RbConfig` host CPU detection.
- **Docker-based challenges** (no example checked in yet — e.g. an "put nginx behind HTTPS" inject) skip Vagrant/Packer/VirtualBox entirely: just a `docker-compose.yml` (plus any config/certs the scenario needs) and a README. Use these for narrow, single-topic injects that don't need a full VM or AD domain — much faster to spin up than the Vagrant path, and there's no shared base image to keep in sync.

Pick the lightest family that fits the scenario: reach for Docker first, fall back to a Linux VM if the challenge genuinely needs systemd services/firewall/SSH-level OS control, and only reach for the Windows/AD box when the challenge is specifically about Active Directory.

**`shared/base.rb`** is required by every Windows challenge Vagrantfile (`require_relative "../../shared/base"`) and centralizes: box name/path, WinRM connection settings, the static private network (`192.168.56.10`) and RDP port forward, VirtualBox provider defaults, and the auto-build-on-missing-box trigger. It also defines `add_linux_vm`, a helper for adding a secondary Linux VM into a multi-machine Windows-based challenge. Changes to shared VM settings (network, credentials, WinRM config) belong here, not duplicated per-challenge.

**Challenge scripts are the challenge.** The provisioning script for each challenge (e.g. `plant-backdoors.ps1`, `break_server.yml`) *is* the scenario definition — it plants the specific vulnerabilities/persistence mechanisms trainees must find. These files carry a `DO NOT READ BEFORE ATTEMPTING` warning; treat them as answer keys and avoid revealing their contents to a user working through a challenge unless asked directly to inspect/modify the challenge setup itself. Each challenge README states a point total and any uptime constraints; the itemized scoring rubric (which names the specific planted artifacts/techniques) lives in `ANSWER.md` instead, and should stay in sync with what the provisioning script actually plants.

**Every challenge must ship a validated answer/walkthrough.** This lives in its own file, separate from `README.md` (e.g. `challenges/<NN-name>/ANSWER.md` or `WALKTHROUGH.md`), and is not something a trainee is meant to open before attempting the lab. Besides the step-by-step solution, `ANSWER.md` is also where each challenge's Learning Objectives, Hints, and (for hunt-style challenges) the itemized scoring breakdown live — keeping every spoiler-bearing section in one place a trainee is explicitly warned off of, rather than scattered across collapsed `<details>` blocks in the README. The challenge author is expected to have personally run the fix against a fresh `vagrant up` to confirm it works, not just derive it by reading the provisioning script. When authoring or editing a challenge, keep three things in lockstep: the provisioning script (what's broken), the scoring rubric in `ANSWER.md` (what's graded), and the step-by-step fix (how to fix it) — if one changes, check the other two.

**Don't spoil the challenge in its own name.** Directory names, README titles, and Scenario/Category text should describe the environment or asset (`08-backup-box`, `22-domain-policies`) rather than the specific vulnerability or attack technique being tested (not `08-cron-stowaway`, not `22-gpo-abuse`) — the technique name belongs in `ANSWER.md`'s Learning Objectives, not in anything visible before a trainee starts. Exceptions: challenges whose whole point is a named skill/task rather than a hidden vulnerability (log triage, pcap analysis, writing a detection rule) can name that task, since knowing you're about to read logs isn't a spoiler the way naming the technique in a find-the-backdoor challenge would be. `Objectives`/`Rules of Engagement` sections for hardening-style challenges (e.g. `03-edge-nginx`, `04-inventory-app`) can and should state the concrete fix required — those challenges hand you a known bad config and test execution, not discovery, so there's no "hunt" to spoil.

**Adding a new challenge**: create `challenges/<NN-name>/README.md` and `ANSWER.md` plus whichever of the above families fits — `Vagrantfile` + `scripts/` for a VM-based challenge (`require_relative "../../shared/base"` and call `apply_base_config(config)` if it's Windows/AD), or `docker-compose.yml` (+ supporting config) for a lightweight one. Validate the answer file end-to-end against a fresh build before considering the challenge done.

**Tracks**: every challenge's README header carries a `**Track:**` line (right after `**Format:**`) of either `AD/Windows` or `Linux/Docker/SIEM` — the two screening tracks. This is independent of family/format (e.g. `18-windows-artifact-hunt` is Docker-format but AD/Windows-track, since its content tests AD/Windows knowledge). When adding a challenge, set `Track:` to whichever track its *subject matter* belongs to, not its underlying family.

## Packaging

`scripts/package-challenge.sh <challenge-dir> [--bundle candidate|instructor|both] [--offline] [--build-box]` zips a challenge up for distribution (e.g. handing it to screening candidates via Google Drive). Output lands in `dist/` at the repo root (gitignored). Run it with no args for full usage.

It always produces two different things, because the provisioning script for a Vagrant-based challenge (`plant-backdoors.ps1`, `break_server.yml`) **is the answer key** per the "Challenge scripts are the challenge" rule above:

- **Instructor bundle** (`<name>-instructor.zip`): the whole directory, answer key and all.
- **Candidate bundle** (`<name>-candidate.zip`): `ANSWER.md` and `scripts/score_me.*` stripped. For Docker challenges that's sufficient — the compromised/vulnerable *content* the candidate needs to find (e.g. a planted webshell file) ships fine, since finding it is the point; only the grading script and the write-up are withheld. For **Windows/AD and Linux-VM (Vagrant) challenges**, stripping isn't enough, because the provisioning script itself runs at `vagrant up` and would still leak the answer — so those candidate bundles instead ship a pre-provisioned `.box` (built once via `--build-box`, which runs `vagrant up` + `vagrant package` + `vagrant destroy`) plus a minimal, provisioning-free Vagrantfile. The `.box` file is separate from the zip (multi-GB, not worth re-compressing) and needs to be uploaded/shared alongside it.

`--offline` (Docker challenges only) additionally `docker save`s the built image(s) into the candidate bundle and rewrites `docker-compose.yml` to reference `image:` instead of `build:`, so the candidate doesn't need registry access — useful for the screening subset where you don't want a slow/flaky first build blocking a timed session.

The shared `ccdc/dc-base` box (see Architecture above) is a one-time dependency for every Windows/AD challenge, distinct from any single challenge's packaged candidate box — build and share it once (`cd packer && packer build .`, then `gzip`/upload the `.box`), not per-challenge.

## Credentials & network (Vagrant challenges)

| Role | Username | Password |
|---|---|---|
| Local Admin | `vagrant` | `vagrant` |
| Domain Admin | `CORP\Administrator` | `P@ssw0rd!` |

Static IP `192.168.56.10`, RDP forwarded on host port `3389`. These are training-lab-only defaults, not a security concern in this context. Docker-based challenges define their own credentials/ports per-challenge in their README since there's no shared compose base yet.
