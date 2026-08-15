# Challenge 14 Answer Key — PCAP Hunt

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's planted
`capture.pcap` is generated deterministically by `scripts/generate_pcap.py`
(committed for reproducibility; requires `scapy`, not a runtime dependency of
the challenge image itself). It contains two flows:
- A plaintext `POST /login` to `10.0.5.30:80` with body
  `username=jdoe&password=Fall2025!`.
- Six UDP packets from the same client to `203.0.113.50:4444`, 30 seconds
  apart, each carrying a `checkin=alive` marker — a C2 beacon.

## Step-by-step fix
1. `docker compose exec app bash`
2. `tshark -r /root/capture.pcap -Y http -x` → shows the POST body in the
   hex/ASCII dump: `username=jdoe&password=Fall2025!`.
3. `tshark -r /root/capture.pcap -Y udp` → six packets to `203.0.113.50:4444`
   at regular ~30s intervals — the beacon.
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
