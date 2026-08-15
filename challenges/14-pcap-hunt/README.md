# Challenge 14: PCAP Hunt

**Category:** Log & Traffic Analysis / Detection
**Difficulty:** Easy
**Time estimate:** 20-30 minutes
**Format:** Docker

## Scenario
A network tap upstream of `intranet.corp` caught a short window of traffic
before someone noticed something odd. Security handed you `capture.pcap` and
nothing else. Find out what leaked, and what's calling home.

## Learning Objectives
- Navigate a pcap with `tshark` (protocol/IO filters, following streams, reading raw payloads)
- Recognize plaintext credential leakage in HTTP traffic
- Recognize periodic beacon/C2 traffic by destination and interval

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

## Hints *(try without these first)*
- `tshark -r /root/capture.pcap -Y http` isolates the login request.
- `tshark -r /root/capture.pcap -Y udp` isolates the non-HTTP traffic — look at destination and interval.
- `tshark -r /root/capture.pcap -x` dumps raw bytes if you'd rather read payloads directly.

## Scoring
From the challenge directory on the host: `docker compose exec app /scripts/score_me.sh`

| Points | Criteria |
|---|---|
| +1 | Correct leaked username |
| +1 | Correct leaked password |
| +1 | Correct beacon destination IP:port |

> **Expected finding count: 3**
