# Challenge 23 Answer Key — SIEM Alert Triage

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's planted
`alerts.json` (see `Dockerfile`) is shaped like a real Wazuh manager alert
log (`/var/ossec/logs/alerts/alerts.json`) — `rule.id`/`rule.level`/
`rule.description`/`rule.groups`, `agent.name`/`agent.ip`, `decoder.name`,
`full_log`, and `location`, instead of a flat custom schema. It contains 29
alerts spanning a full day across `web01`, a second web host, a VPN gateway,
and several workstation agents. 24 of them are noise, all at `rule.level` 3
or 5:
- Scanner ranges (`203.0.113.9`, `198.51.100.201`) throwing failed SSH
  logins (`rule.id 100010`, level 5) at various agents all day, none of
  which ever succeed.
- Routine informational activity at level 3: AV signature updates
  (`100020`), baseline process starts (`100040`), successful VPN logins
  (`100050`), and first-seen-but-approved outbound connections to new
  vendor domains (`100030`).

The real intrusion is 5 alerts, the only ones at `rule.level` 7 or higher,
all tied to `data.srcip`/`data.dstip` `198.51.100.44` and/or agent `web01`
(`10.0.2.15`), inside a ~40-minute window starting at 09:14 UTC:
- `1042` — Web Recon Scan Detected (`rule.id 100060`, level 7 — external
  host scans `/app` paths)
- `1047` — SQL Injection Attempt Blocked (`rule.id 100061`, level 7 —
  modsecurity matched, but the request still reached the app layer per
  `full_log`'s `200` status — this is the actual initial-access vector)
- `1051` — Anomalous Outbound Shell (`rule.id 100070`, level 12 — web01
  calls back out to the same external IP on port 4444)
- `1053` — New Local Admin Account Created (`rule.id 100080`, level 12 —
  `svc_update` added to Administrators on web01)
- `1058` — Scheduled Task Created by Non-Admin Context (`rule.id 100081`,
  level 12 — `SysHealthCheck` persistence, created moments after the new
  admin account)

## Step-by-step fix
1. `docker compose exec app bash`
2. `jq '.[] | .rule.level' /var/ossec/logs/alerts/alerts.json | sort -n | uniq -c`
   — shows 18 alerts at level 3, 8 at level 5, 2 at level 7, 3 at level 12.
   The level-7-and-up alerts are the ones worth reading first.
3. `jq '.[] | select(.rule.level >= 7)' /var/ossec/logs/alerts/alerts.json`
   → returns exactly the 5-alert chain (`1042, 1047, 1051, 1053, 1058`),
   sorted by timestamp, all within the 09:14–09:52 window, all tied to
   `198.51.100.44` and/or agent `web01`.
4. `jq '.[] | select(.rule.id=="100061")' /var/ossec/logs/alerts/alerts.json`
   → confirms `1047`'s `rule.description` is "SQL injection pattern matched
   in request parameter" and its `full_log` shows the `' OR '1'='1` payload
   reaching `login.php` with a `200` response — that's the root cause.
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
