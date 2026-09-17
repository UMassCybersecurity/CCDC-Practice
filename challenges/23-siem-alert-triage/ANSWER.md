# Challenge 23 Answer Key — SIEM Alert Triage

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's planted
`alerts.json` (see `Dockerfile`) contains 29 alerts spanning a full day on
`web01` and several other hosts. 24 of them are noise:
- Scanner ranges (`203.0.113.9`, `198.51.100.201`) throwing failed logins at
  various hosts all day, none of which ever succeed.
- Routine informational activity: AV signature updates, scheduled backup/print
  processes starting on their normal baseline, VPN logins from registered
  devices, first-seen-but-approved outbound connections to new vendor domains.

The real intrusion is 5 alerts, all tied to source IP `198.51.100.44` and/or
asset `web01` (`10.0.2.15`), inside a ~40-minute window starting at 09:14 UTC:
- `1042` — Web Recon Scan Detected (external host scans `/app` paths)
- `1047` — SQL Injection Attempt Blocked (WAF matched, but the request still
  reached the app layer — this is the actual initial-access vector)
- `1051` — Anomalous Outbound Shell (web01 calls back out to the same
  external IP on port 4444)
- `1053` — New Local Admin Account Created (`svc_update` added to
  Administrators on web01)
- `1058` — Scheduled Task Created by Non-Admin Context (`SysHealthCheck`
  persistence, created moments after the new admin account)

## Step-by-step fix
1. `docker compose exec app bash`
2. `jq '.[] | .rule_name' /var/log/alerts.json | sort | uniq -c` — shows
   `Multiple Failed Logins`, `New Process Created`, `Antivirus Signature
   Update`, `Outbound Connection to New Domain`, and `VPN Login Success`
   repeating many times; `Web Recon Scan Detected`, `SQL Injection Attempt
   Blocked`, `Anomalous Outbound Shell`, `New Local Admin Account Created`,
   and `Scheduled Task Created by Non-Admin Context` each appear exactly once.
3. `jq '.[] | select(.rule_name=="SQL Injection Attempt Blocked")' /var/log/alerts.json`
   → source `198.51.100.44`, dest `10.0.2.15`, `id: 1047`.
4. `jq --arg ip "198.51.100.44" '.[] | select(.source_ip==$ip or .dest_ip==$ip)' /var/log/alerts.json`
   → pulls back exactly the 5-alert chain (`1042, 1047, 1051, 1053, 1058`),
   sorted by timestamp, all within the 09:14–09:52 window.
5. Write to `/root/findings.txt`:
   ```
   TRUE_POSITIVES: 1042,1047,1051,1053,1058
   ROOT_CAUSE: sql injection
   ```

## Validation
Ran `docker compose up -d --build` fresh, confirmed
`docker compose exec app /scripts/score_me.sh` reports `0 / 2` with no
`findings.txt` present. Wrote the two lines above to `/root/findings.txt`
inside the container via `docker compose exec app sh -c "printf 'TRUE_POSITIVES: 1042,1047,1051,1053,1058\nROOT_CAUSE: sql injection\n' > /root/findings.txt"`
and confirmed `score_me.sh` reports `2 / 2`. Torn down with
`docker compose down -v --rmi local` afterward.
