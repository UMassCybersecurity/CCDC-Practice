# Challenge 19: Standalone Windows Hardening

**Category:** Host Hardening / Misconfiguration Audit
**Difficulty:** Easy-Medium
**Time estimate:** 25-35 minutes
**Format:** Vagrant (Windows)
**Track:** AD/Windows

## Scenario
A standalone Windows server was stood up quickly for a project and never got a proper hardening pass. Nothing has been compromised (yet) — this is a proactive audit. Find the local misconfigurations before someone else does.

## Objectives
- Find and remediate the local hardening issues on this box
- Do not break the box's ability to accept RDP connections

## Prerequisites
This challenge runs a Windows Server 2022 VM on VirtualBox and **requires an x86 host** (Windows, Linux, or Intel Mac). It does **not** run on Apple Silicon Macs (M1/M2/M3/M4). Full details are in the [main README](../../README.md#prerequisites).

**For Windows, Linux, and Intel-based Macs (x86):**
1. Install [VirtualBox](https://www.virtualbox.org/).
2. Install [Vagrant](https://www.vagrantup.com/).
3. Install [Packer](https://developer.hashicorp.com/packer/install). The first `vagrant up` uses it to build the shared Windows base box (~20-30 min, one time only).
4. Have an RDP client ready:
   - **Windows:** built in (`vagrant rdp` opens `mstsc`).
   - **Mac:** install Microsoft's **Windows App** (formerly Microsoft Remote Desktop) from the Mac App Store.
   - **Linux:** Remmina or `xfreerdp`.

**For Apple Silicon Macs (M1/M2/M3/M4):**
Not supported. VirtualBox doesn't run on Apple Silicon, and this challenge's Windows base box is x86-only. Use an x86 machine instead.

## Connect
| Field | Value |
|---|---|
| **Start** | `vagrant up` (~2-3 min once the base box is built) |
| **RDP To** | 192.168.56.10 (or `vagrant rdp`) |
| **Username** | vagrant |
| **Password** | vagrant |

## Rules of Engagement
- Do not disable RDP entirely — you still need to get back in.
- Fix the misconfigurations in place; you don't need to reinstall or reimage anything.

## Scoring
Run `C:\vagrant\scripts\score_me.ps1` inside the VM as Administrator.

**5 points total.** Full breakdown is in ANSWER.md.
