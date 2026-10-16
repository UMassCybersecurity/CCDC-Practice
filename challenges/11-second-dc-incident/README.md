# Challenge 11: Another Domain Controller Incident

**Category:** Persistence & Backdoor Hunting
**Difficulty:** Hard
**Time estimate:** 40-60 minutes
**Format:** Vagrant (Windows/AD)
**Track:** AD/Windows

## Scenario
corp.local's domain controller was compromised again — a different attacker than the one from Challenge 01, using a different playbook. This one favored quieter, more privileged techniques than last time. Find all five and remove them without breaking the domain.

## Objectives
- Identify and remove all 5 persistence mechanisms
- Keep Active Directory Domain Services and DNS running throughout
- Document what you found (technique, artifact, how it was remediated)

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
| **RDP To** | 192.168.56.10 |
| **Username** | CORP\jsmith |
| **Password** | Welcome1! |
| **Domain Admin** | CORP\Administrator / P@ssw0rd! |

## Rules of Engagement
- Do not break AD DS or DNS.
- Do not remove legitimate user accounts (`jsmith`, built-in accounts).

## Scoring
Run `C:\vagrant\scripts\score_me.ps1` inside the VM as Administrator.

**7 points total.** Full breakdown is in ANSWER.md.
