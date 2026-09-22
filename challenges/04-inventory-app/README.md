# Challenge 04: The Inventory App

**Category:** Service Hardening & Secure Configuration
**Difficulty:** Easy
**Time estimate:** 20-30 minutes
**Format:** Docker
**Track:** Linux/Docker/SIEM

## Scenario
WidgetCorp's "inventory-app" stores its counters in Redis. Whoever wired this up published Redis straight to the host with no password, so anyone who can reach port 8101 has full read/write access to the datastore behind your application.

## Objectives
- Require authentication on Redis
- Redis should no longer be reachable directly from the host
- The `inventory-app` must keep working against the now-authenticated Redis

## Connect
| Field | Value |
|---|---|
| **Start** | `docker compose up -d --build` (from this directory) |
| **App** | http://localhost:8102 (`/health`, `/items`) |
| **Redis (currently exposed)** | localhost:8101 |
| **Edit** | `docker-compose.yml` — add Redis auth and app env, then `docker compose up -d` to apply |

## Rules of Engagement
- The `inventory-app`'s `/health` endpoint must keep returning 200 with a working Redis connection.

## Scoring
Run `./scripts/score_me.sh` from this directory on the host.

**3 points total.** Full breakdown is in ANSWER.md.
