# Challenge 24 Answer Key — Multi-Source Log Correlation

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's planted
Three static logs baked into the image (`logs/nginx_access.log`, `logs/app.log`,
`logs/auth.log`), all sharing one day's timeline (Jun 2):

- **`nginx_access.log`**: normal storefront traffic from internal `10.0.5.x`
  addresses, unrelated `wp-login.php`/`.env` scanner noise from `198.51.100.5`,
  and the real chain from `203.0.113.44` — recon against `/admin`,
  `/admin/login.php`, `/phpmyadmin` (all 404), then `GET /upload.php` (loads
  the form), then `POST /upload.php` at `14:03:41` which succeeds, then the
  attacker fetching `/uploads/cfg_9f3a.php` and hitting it with `?cmd=`
  parameters.
- **`app.log`**: mirrors the same requests from the app's own perspective,
  and is the only log that says *why* the upload mattered — a `WARN` at
  `14:03:41` reporting an unauthenticated file write to
  `/var/www/html/uploads/cfg_9f3a.php` because `upload.php` has no auth check
  and no extension allowlist. Two subsequent `WARN` lines flag unexpected
  child processes spawned by `www-data` — the webshell executing commands.
- **`auth.log`**: normal SSH noise (`jsmith`, `svc-backup` legitimate
  logins; unrelated failed-password scanning from `198.51.100.5`), then at
  `14:16:33` — about 13 minutes after the exploit — a `sudo` entry showing
  `www-data` (the web server's own user) running a passwordless-sudo command
  as root that appends an SSH key to `/root/.ssh/authorized_keys`. This is
  the persistence step, and it doesn't come from `203.0.113.44` at all —
  the attacker is pivoting through the already-compromised web app.

## Step-by-step fix
1. `docker compose exec app bash`
2. `grep "40[0-9] \| 20[0-9] " /var/log/nginx_access.log | grep -v "10.0.5\|198.51.100.5"` (or just eyeball it) →
   `203.0.113.44` is the only IP doing `/admin`/`/phpmyadmin` recon followed by a
   successful `POST /upload.php` at `14:03:41`.
3. `grep "14:0[2-4]" /var/log/app.log` → the `WARN unauthenticated file write to
   /var/www/html/uploads/cfg_9f3a.php` line at the same timestamp confirms
   `/upload.php` is the exploited endpoint.
4. `grep -A2 -B2 "14:1" /var/log/auth.log` → the `sudo`/`www-data` entry at
   `14:16:33` appending to `/root/.ssh/authorized_keys` is the persistence —
   note it's timestamped a few minutes after the exploit and has nothing to
   do with `203.0.113.44` directly, which is the trap in this challenge.
5. Write to `/root/findings.txt`:
   ```
   IP: 203.0.113.44
   ENDPOINT: /upload.php
   PERSISTENCE: authorized_keys entry appended for root via www-data sudo
   TIME: 02/Jun/2026:14:03:41 +0000
   ```

## Validation
Ran `docker compose up -d --build`, confirmed `docker compose exec app
/scripts/score_me.sh` reported `0 / 4` with no `findings.txt` present. Then:
```
docker compose exec app sh -c 'cat > /root/findings.txt <<EOF
IP: 203.0.113.44
ENDPOINT: /upload.php
PERSISTENCE: authorized_keys entry appended for root via www-data sudo
TIME: 02/Jun/2026:14:03:41 +0000
EOF'
docker compose exec app /scripts/score_me.sh
```
confirmed `4 / 4`. Torn down with `docker compose down -v --rmi local` afterward.
