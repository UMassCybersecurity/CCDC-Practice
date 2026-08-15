# Challenge 13 Answer Key — Log Triage

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's planted
`auth.log` is a static, hand-written log baked into the image (see `Dockerfile`,
`auth.log`). It contains three interleaved stories:
- Noise: scanning IPs `198.51.100.23` and `192.0.2.55` throwing failed logins
  at `admin`, `root`, `postgres`, `test`, `oracle` — none of these ever succeed.
- Legitimate activity: `svc-backup` and `jsmith` logging in cleanly from
  internal `10.0.5.x` addresses.
- The real incident: `203.0.113.77` brute-forces `dave` with 8 failed
  passwords, succeeds at `Mar 14 02:11:03`, reconnects via a now-authorized
  SSH key two minutes later, and edits `dave`'s crontab — persistence planted
  post-compromise.

## Step-by-step fix
1. `docker compose exec app bash`
2. `grep "Accepted" /var/log/auth.log` → shows `dave` accepted from
   `203.0.113.77` at `Mar 14 02:11:03`.
3. `grep "203.0.113.77" /var/log/auth.log` → confirms the repeated failed
   attempts against `dave` immediately preceding it, and the crontab edit
   immediately after — this is the compromise, not the noise IPs.
4. Write to `/root/findings.txt`:
   ```
   IP: 203.0.113.77
   USER: dave
   TIME: Mar 14 02:11:03
   ```

## Validation
Ran `docker compose up -d --build` fresh, confirmed `score_me.sh` reports
`0 / 3` with no `findings.txt` present, then wrote the three lines above to
`/root/findings.txt` inside the container and confirmed `score_me.sh` reports
`3 / 3`. Torn down with `docker compose down -v` afterward.
