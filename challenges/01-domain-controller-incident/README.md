# Challenge 01: Domain Controller Incident

**Category:** Persistence & Backdoor Hunting
**Difficulty:** Medium
**Time estimate:** 30-60 minutes
**Format:** Vagrant (Windows/AD)
**Track:** AD/Windows

## Scenario
Your organization's domain controller was compromised last weekend. The incident response team removed the initial malware, but they suspect the attacker left multiple persistence mechanisms behind. Your job: find and remove **ALL** of them.

## Objectives
- Identify all persistence mechanisms the attacker planted
- Remove them without breaking legitimate services
- Document what you found *(attacker's username, methods used, etc.)*

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
- Do not remove legitimate accounts.

## Scoring
Run `C:\vagrant\scripts\score_me.ps1` inside the VM as Administrator.

**8 points total.** Full breakdown is in ANSWER.md.
