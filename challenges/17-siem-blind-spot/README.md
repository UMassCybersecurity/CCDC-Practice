# Challenge 17: SIEM Blind Spot

**Category:** Log & Traffic Analysis / Detection
**Difficulty:** Medium
**Time estimate:** 40-60 minutes
**Format:** Vagrant (Linux)

## Scenario
`prod-app04`'s logs look clean — suspiciously clean. Someone tampered with
the logging pipeline before you got here, and whatever they were hiding is
still running. You need to restore visibility first, then use it to find
what's actually going on.

<details>
<summary><strong>Learning Objectives</strong> (spoiler — click to reveal)</summary>

- Recognize a logging pipeline that's been tampered with to create a blind spot
- Understand how rsyslog filtering/discard rules can selectively hide activity
- Use restored visibility (and direct system inspection) to find a hidden persistence mechanism

</details>

## Objectives
- Find and remove whatever is suppressing log visibility, and get logging working normally again
- Find and remove the persistence mechanism that suppression was hiding
- Keep the Apache web service online throughout

## Connect
| Field | Value |
|---|---|
| **Start** | `vagrant up` |
| **Connect** | `vagrant ssh` |
| **IP** | `192.168.56.10` |

## Rules of Engagement
- **DO NOT** stop the Apache2 web service. It must remain online.
- **DO NOT** just disable rsyslog entirely to "fix" the blind spot — that trades one blind spot for a bigger one. Fix the actual filter.

<details>
<summary><strong>Hints</strong> (try without these first — click to reveal)</summary>

- rsyslog reads config from `/etc/rsyslog.conf` and everything under `/etc/rsyslog.d/`.
- A `stop` in an rsyslog filter action drops the message entirely — it never reaches the log files.
- Once you know what's being hidden, `crontab -l -u <user>` for suspicious local accounts is a fast next step.

</details>

## Scoring
Inside the VM: `sudo /vagrant/scripts/score_me.sh`

<details>
<summary>Scoring criteria (spoiler — click to reveal)</summary>

| Points | Criteria |
|---|---|
| +1 | rsyslog filter suppressing the hidden user's log lines is removed |
| +1 | rsyslog service still running (logging actually restored, not disabled) |
| +1 | Hidden persistence mechanism removed |
| +1 | Apache web server still online |

> **Expected finding count: 1 logging blind spot + 1 hidden persistence mechanism**

</details>
