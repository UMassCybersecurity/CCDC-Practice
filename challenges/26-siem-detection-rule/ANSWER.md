# Challenge 26 Answer Key — SIEM Detection Rule

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's planted
`auth.log` (hand-written, static) contains four groups of activity across one day:
- **Known-good users**: `jsmith` (10.0.4.15, 3 clean logins), `mgarcia`
  (10.0.4.22, 3 logins — two during business hours, one legitimate off-hours
  on-call login at 22:15), `twong` (203.0.113.50, 2 logins — the first
  preceded by 2 failed attempts, a typo, not an attack).
- **Noise scanners**: `198.51.100.9` and `192.0.2.77`, each throwing several
  `Failed password` attempts at `root`/`admin`/`test`/`oracle`/`postgres`
  that never succeed.
- **CRON noise**: routine `sessionclean` cron lines, irrelevant to SSH auth.
- **The real incident**: `45.33.12.201` — never seen anywhere else in the
  log — logs in as `svc-deploy` at `03:14:22` (off-hours) with **zero**
  preceding failed attempts from that IP. Valid credentials, used correctly,
  on the first try.

The trap: filtering on "off-hours login" alone also catches `mgarcia`'s
22:15 login — a real false positive. The rule needs both conditions (off-hours
**and** source IP never seen elsewhere in the log) to isolate exactly one line.

## Step-by-step fix
1. `docker compose exec app bash`
2. Count how many times each source IP appears anywhere in the log, then
   cross-reference against successful logins outside 08:00-18:00:
   ```bash
   awk '
     FNR==NR { count[$11]++; next }
     /Accepted password/ {
       ip=$11; user=$9
       split($3, t, ":"); hour = t[1] + 0
       if ((hour < 8 || hour >= 18) && count[ip] == 1) print ip":"user
     }
   ' /var/log/auth.log /var/log/auth.log > /root/alerts.log
   ```
   (The file is read twice via the `FNR==NR` idiom: the first pass builds a
   per-IP occurrence count, the second pass applies the off-hours + first-seen
   filter to `Accepted password` lines.)
3. Confirm `/root/alerts.log` contains exactly `45.33.12.201:svc-deploy`.

## Validation
Ran `docker compose up -d --build` fresh, confirmed `score_me.sh` reports
`0 / 3` with no `alerts.log` present. Dry-ran the awk detector above inside
the container and confirmed it printed exactly one line,
`45.33.12.201:svc-deploy`, with no false positive on `mgarcia`'s 22:15
off-hours login. Wrote that output to `/root/alerts.log` and confirmed
`score_me.sh` reports `3 / 3`. Torn down with `docker compose down -v
--rmi local` afterward.
