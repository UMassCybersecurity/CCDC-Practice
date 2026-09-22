# Challenge 23 Answer Key — SIEM Alert Triage

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## Learning Objectives
- Read Wazuh's native alert JSON shape (`rule.level`/`rule.description`, `agent`, `full_log`, `decoder`) with `jq`
- Use `rule.level` the way a SOC analyst does: as the first triage filter, not the `severity` label
- Distinguish a genuine multi-stage intrusion from high-volume background noise
- Correlate alerts by `agent`, `data.srcip`/`data.dstip`, and time window into a single incident

## Hints
- `jq '.[] | .rule.level' alerts.json | sort -n | uniq -c` shows the level distribution — in Wazuh, `rule.level` is the first thing you filter on, not the rule name.
- `jq '.[] | select(.rule.level >= 7)'` cuts straight past the noise levels to what's actually worth reading.
- Once you find one alert you're confident is real, cross-reference its `data.srcip`/`data.dstip` against the other level-7+ alerts — a plain `agent.name` match alone now also pulls in a lot of that agent's routine low-level noise, so filter by IP first.
- The real chain lives in about a 40-minute window — among just the level-7+ alerts, sort by timestamp and look for a tight cluster on one agent, not an isolated single alert or a burst that never escalates.

## Scoring breakdown
| Points | Criteria |
|---|---|
| +1 | Every true-positive alert ID in the chain identified, no noise IDs included |
| +1 | Correct root-cause technique named |

## What's planted
`alerts.json` (see `Dockerfile`) is shaped like a real Wazuh manager alert
log (`/var/ossec/logs/alerts/alerts.json`) — `rule.id`/`rule.level`/
`rule.description`/`rule.groups`, `agent.name`/`agent.ip`, `decoder.name`,
`full_log`, and `location`, instead of a flat custom schema. It contains 242
alerts spanning a full day across `web01`, a second web host, a VPN gateway,
and several workstation agents. 237 of them are noise:
- 224 alerts at `rule.level` 3 or 5: scanner ranges throwing failed SSH
  logins (`rule.id 100010`), routine AV signature updates (`100020`),
  baseline process starts (`100040`), successful VPN logins (`100050`),
  first-seen-but-approved outbound connections to new vendor domains
  (`100030`), plus three added decoder/rule categories for diversity —
  `sudo` command execution (`100090`), PAM session open/close (`100091`),
  and routine `web-accesslog` GET traffic (`100092`).
- **13 elevated decoys at `rule.level` 7-9** that never form a second real
  chain — this is the key fix over the original version, where `rule.level
  >= 7` returned *only* the 5 real alerts with nothing to filter past. The
  decoys: three isolated blocked-SQLi probes against `web01`/`web02` from
  scanner IPs with no follow-through; a 6-alert "authorized pentest" burst
  against `web02` from an internal IP (`10.0.9.50`, 11:00-11:30) that
  triggers recon + SQLi-pattern rules but never escalates to a shell/admin
  account/scheduled task; a legitimate, ticketed admin-group change on
  `fin-ws07` (`jchen`, ticket `HELP-4471`) that fires the same
  privilege-escalation rule the real incident does, just on a different
  host with no surrounding chain; a one-off AV quarantine-failure alert;
  and two more isolated web-recon hits against `web01` from other scanner
  IPs that never escalate. None of these share both the real incident's
  source IP (`198.51.100.44`) and agent (`web01`) inside its time window —
  confirmed programmatically before committing.

The real intrusion is still the same 5 alerts, correlated by
`data.srcip`/`data.dstip` `198.51.100.44` and/or agent `web01`
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
   — shows 116 alerts at level 3, 108 at level 5, 10 at level 7, 4 at level
   8, 1 at level 9, and 3 at level 12. The 18 level-7-and-up alerts are the
   ones worth reading first.
3. `jq '.[] | select(.rule.level >= 7)' /var/ossec/logs/alerts/alerts.json`
   → returns 18 alerts, not just the real chain — several isolated blocked
   scans/SQLi probes, a 6-alert internal "pentest" burst against `web02`,
   one legitimate ticketed admin-group change on `fin-ws07`, and one AV
   quarantine failure are mixed in. Pivot by IP/agent (next step) to isolate
   the real chain from these decoys.
4. `jq 'sort_by(.timestamp) | .[] | select(.rule.level >= 7) | {id, timestamp, agent: .agent.name}' /var/ossec/logs/alerts/alerts.json`
   → sorted by time, the 18 elevated alerts cluster into distinct, separate
   incidents: an isolated single alert here and there, a 6-alert burst on
   `web02` all within 11:00-11:30, one isolated alert on `fin-ws07` at
   14:05 — and one tight cluster of exactly 5 alerts, all on `web01`,
   spanning just 09:14-09:52. That cluster is `1042, 1047, 1051, 1053,
   1058` — the only elevated alerts that actually escalate stage-by-stage
   (recon → SQLi → shell → new admin → persistence) rather than sitting
   alone or plateauing.
5. `jq '.[] | select(.rule.id=="100061")' /var/ossec/logs/alerts/alerts.json`
   → confirms `1047`'s `rule.description` is "SQL injection pattern matched
   in request parameter" and its `full_log` shows the `' OR '1'='1` payload
   reaching `login.php` with a `200` response — that's the root cause.
6. Write to `/root/findings.txt`:
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

Re-validated on 2026-09-18 after expanding `alerts.json` from 29 to 242
alerts, specifically adding 13 elevated (level 7-9) decoys so `rule.level >=
7` no longer returns only the 5 real-chain alerts. Before touching the
container, programmatically confirmed none of the added decoys share both
the real incident's source IP (`198.51.100.44`) and agent (`web01`) inside
its 09:14-09:52 window, and confirmed the level distribution (116@3, 108@5,
10@7, 4@8, 1@9, 3@12). Ran a fresh `docker compose up -d --build`, confirmed
`jq` inside the container reproduces that same distribution and the same 18
level-7+ IDs, confirmed `score_me.sh` reports `0 / 2` with no `findings.txt`,
wrote the same two findings lines and confirmed `2 / 2`, then confirmed a
findings file naming a decoy ID alongside the real chain correctly fails
(`1 / 2`). Torn down with `docker compose down -v` afterward.
