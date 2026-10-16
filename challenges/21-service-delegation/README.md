# Challenge 21: Service Account Delegation

**Category:** Active Directory / Security Review
**Difficulty:** Hard
**Time estimate:** 45-60 minutes
**Format:** Vagrant (Windows/AD)
**Track:** AD/Windows

## Scenario
A low-privilege service account on `corp.local` was delegated some rights months ago "temporarily" and nobody ever audited what those rights actually granted. Figure out what that account can really do in the domain, and lock it down.

## Objectives
- Figure out exactly what the over-permissioned account can do in the domain
- Remove the excess rights without breaking AD DS
- Document what you found *(account name, rights granted, on which objects)*

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
- Do not remove the `svc-monitor` account itself — it's a legitimate (if over-permissioned) service account. Just fix its rights.
- Do not touch AdminSDHolder — that's not where this one lives.

## Scoring
Run `C:\vagrant\scripts\score_me.ps1` inside the VM as Administrator.

**4 points total.** Full breakdown is in ANSWER.md.
