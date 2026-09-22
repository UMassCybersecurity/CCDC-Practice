# Challenge 14: PCAP Hunt

**Category:** Log & Traffic Analysis / Detection
**Difficulty:** Easy
**Time estimate:** 20-30 minutes
**Format:** Docker
**Track:** Linux/Docker/SIEM

## Scenario
A network tap upstream of `intranet.corp` caught a short window of traffic
before someone noticed something odd. Security handed you `capture.pcap` and
nothing else. Find out what leaked, and what's calling home.

## Objectives
- Recover the plaintext username and password submitted over HTTP
- Identify the destination IP and port of the periodic beacon traffic
- Write your findings to `/root/findings.txt` inside the container

## Connect
| Field | Value |
|---|---|
| **Start** | `docker compose up -d --build` |
| **Shell in** | `docker compose exec app bash` |
| **Capture file** | `/root/capture.pcap` inside the container |
| **Findings file** | `/root/findings.txt` inside the container (you create this) |

## Rules of Engagement
- This is a read-only analysis exercise — there is nothing to break, only a capture to read.

## Findings format
Write exactly these three lines to `/root/findings.txt` (no extra text):
```
USER: <leaked username>
PASS: <leaked password>
BEACON: <destination IP>:<destination port>
```

## Scoring
From the challenge directory on the host: `docker compose exec app /scripts/score_me.sh`

**3 points total.** Full breakdown is in ANSWER.md.
