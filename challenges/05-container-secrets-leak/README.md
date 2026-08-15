# Challenge 05: Container Secrets Leak

**Category:** Service Hardening & Secure Configuration
**Difficulty:** Easy
**Time estimate:** 20-30 minutes
**Format:** Docker

## Scenario
A dev spun up WidgetCorp's public API container and never took the training wheels off: debug mode is still on, an API key is hardcoded and echoed back on a status page, and the static file route will happily serve any file in its directory — including the `.env` sitting right next to the legit assets.

## Learning Objectives
- Recognize and disable a Flask debug-mode information leak
- Stop an application from echoing secrets back over an API
- Prevent dotfile/config exposure through a static file route
- Rebuild a container after a code fix and confirm behavior actually changed

## Objectives
- `/crash` must not leak a stack trace
- `/status` must not leak the API key
- `/files/.env` must not be servable
- The main page and the legitimate static asset (`/files/logo.txt`) must keep working

## Connect
| Field | Value |
|---|---|
| **Start** | `docker compose up -d --build` (from this directory) |
| **App** | http://localhost:8103 |
| **Edit** | `app/app.py`, then `docker compose up -d --build` to rebuild and apply |

## Rules of Engagement
- Keep `/` and `/files/logo.txt` returning 200 the whole time.

## Hints *(try without these first)*
- `app.run(debug=True)` is what turns crashes into an interactive traceback page — turn it off.
- The API key doesn't need to be *in* the `/status` response at all to prove it's configured.
- `send_from_directory` will serve anything in the directory you point it at, including dotfiles, unless you explicitly reject them.
- Remember to rebuild (`docker compose up -d --build`) after editing `app.py` — this app isn't bind-mounted, so a plain restart won't pick up your change.

## Scoring
Run `./scripts/score_me.sh` from this directory on the host.

| Points | Criteria |
|---|---|
| +1 | `/crash` no longer leaks a debug traceback |
| +1 | `/status` no longer leaks the API key |
| +1 | `/files/.env` is blocked (403/404) |
| +1 | `/` and `/files/logo.txt` still return 200 |

> **Expected finding count: 4**
