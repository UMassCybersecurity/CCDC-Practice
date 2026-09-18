# Challenge 14 Answer Key — PCAP Hunt

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## Learning Objectives
- Navigate a pcap with `tshark` (protocol/IO filters, following streams, reading raw payloads)
- Recognize plaintext credential leakage in HTTP traffic
- Recognize periodic beacon/C2 traffic by destination and interval

## Hints
- `tshark -r /root/capture.pcap -Y http` isolates the HTTP traffic — there are
  several benign GET requests mixed in with the one real `POST /login`, so
  check each flow's method, not just that `-Y http` returned something.
- `tshark -r /root/capture.pcap -Y udp -T fields -e ip.dst | sort | uniq -c`
  groups the UDP traffic by destination — DNS and syslog noise dominate, but
  one destination (the beacon) stands out by its low, regular packet count.
- `tshark -r /root/capture.pcap -Y "ip.dst==<beacon ip>"` once you've spotted
  it above shows the exact ~30s interval.
- `tshark -r /root/capture.pcap -x` dumps raw bytes if you'd rather read payloads directly.

## What's planted
`capture.pcap` is generated deterministically by `scripts/generate_pcap.py`
(committed for reproducibility; requires `scapy`, not a runtime dependency of
the challenge image itself; fixed RNG seed 1337 for the noise, so
regenerating produces a byte-identical file). It contains 361 packets total:
- The two real signals, timestamps/payloads unchanged from the original
  version: a plaintext `POST /login` to `10.0.5.30:80` with body
  `username=jdoe&password=Fall2025!`, and six UDP packets from the same
  client to `203.0.113.50:4444`, 30 seconds apart, each carrying a
  `checkin=alive` marker.
- Noise: 25 benign HTTP GET flows (5 client IPs against 3 internal servers),
  60 DNS query/response pairs against an internal resolver, and 80 one-way
  "syslog" UDP packets to a log collector — so neither `-Y http` nor `-Y udp`
  trivially isolates the real signal by count alone; the beacon has to be
  spotted by its destination/cadence, not by being the only thing in the
  filtered view.

## Step-by-step fix
1. `docker compose exec app bash`
2. `tshark -r /root/capture.pcap -Y http` → several GET flows plus one
   `POST /login`; `tshark -r /root/capture.pcap -Y "http.request.method==POST" -x`
   shows the POST body in the hex/ASCII dump: `username=jdoe&password=Fall2025!`.
3. `tshark -r /root/capture.pcap -Y udp -T fields -e ip.dst | sort | uniq -c` →
   one destination (`203.0.113.50`) has exactly 6 packets versus dozens for
   DNS/syslog; `tshark -r /root/capture.pcap -Y "ip.dst==203.0.113.50"` confirms
   the regular ~30s interval — the beacon.
4. Write to `/root/findings.txt`:
   ```
   USER: jdoe
   PASS: Fall2025!
   BEACON: 203.0.113.50:4444
   ```

## Validation
Ran `docker compose up -d --build` fresh, confirmed `score_me.sh` reports
`0 / 3` with no `findings.txt` present, then wrote the three lines above to
`/root/findings.txt` inside the container and confirmed `score_me.sh` reports
`3 / 3`. Torn down with `docker compose down -v` afterward.

Re-validated on 2026-09-18 after regenerating `capture.pcap` with 165 added
noise packets (25 benign HTTP flows, 60 DNS pairs, 80 syslog packets) around
the unchanged real signal. Confirmed via `tshark` that `-Y http` now returns
26 flows (not 1) and `-Y udp` now returns 206 packets across three
destinations (not just the beacon's 6) — the documented grouping/filtering
technique above still isolates both real answers cleanly. Ran a fresh
`docker compose up -d --build`, confirmed `score_me.sh` reports `0 / 3` with
no `findings.txt`, wrote the same three findings lines, and confirmed
`3 / 3`. Torn down with `docker compose down -v` afterward.
