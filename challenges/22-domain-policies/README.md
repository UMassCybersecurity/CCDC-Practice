# Challenge 22: Domain Group Policy Review

**Category:** Active Directory / Security Review
**Difficulty:** Medium
**Time estimate:** 35-50 minutes
**Format:** Vagrant (Windows/AD)
**Track:** AD/Windows

## Scenario
`corp.local` has several Group Policy Objects linked at the domain root. Most are boring, legitimate desktop-configuration policies. One of them isn't — something about it doesn't add up.

## Objectives
- Identify the one rogue GPO among the legitimate ones
- Remove it entirely without touching the legitimate GPOs
- Document what you found *(GPO name, payload, delivery mechanism)*

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
| **Username** | CORP\jsmith |
| **Password** | Welcome1! |
| **Domain Admin** | CORP\Administrator / P@ssw0rd! |

## Rules of Engagement
- Do not break AD DS or DNS.
- Do not delete or unlink any of the legitimate GPOs — only the rogue one.

## Scoring
Run `C:\vagrant\scripts\score_me.ps1` inside the VM as Administrator.

**3 points total.** Full breakdown is in ANSWER.md.
