# Challenge 05: The Public API

**Category:** Service Hardening & Secure Configuration
**Difficulty:** Easy
**Time estimate:** 20-30 minutes
**Format:** Docker
**Track:** Linux/Docker/SIEM

## Scenario
A dev spun up WidgetCorp's public API container and never took the training wheels off: debug mode is still on, an API key is hardcoded and echoed back on a status page, and the static file route will happily serve any file in its directory — including the `.env` sitting right next to the legit assets.

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

## Scoring
Run `./scripts/score_me.sh` from this directory on the host.

**4 points total.** Full breakdown is in ANSWER.md.
