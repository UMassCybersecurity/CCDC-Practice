# Challenge 04: Exposed Datastore

**Category:** Service Hardening & Secure Configuration
**Difficulty:** Easy
**Time estimate:** 20-30 minutes
**Format:** Docker

## Scenario
WidgetCorp's "inventory-app" stores its counters in Redis. Whoever wired this up published Redis straight to the host with no password, so anyone who can reach port 8101 has full read/write access to the datastore behind your application.

<details>
<summary><strong>Learning Objectives</strong> (spoiler — click to reveal)</summary>

- Add authentication to a datastore that ships with none by default
- Stop publishing an internal service to the host network
- Wire a new credential through to a dependent application via environment variables
- Verify a fix doesn't break the service that depends on it

</details>

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

<details>
<summary><strong>Hints</strong> (try without these first — click to reveal)</summary>

- `redis-server --requirepass <password>` is the quickest way to add auth to the `redis` service's `command:`.
- The app needs that same password passed in via an environment variable so it can still connect.
- Dropping the `ports:` mapping on the `redis` service removes host access entirely — containers on the same compose network can still reach it by service name.
- `docker compose up -d` picks up compose file changes without a rebuild.

</details>

## Scoring
Run `./scripts/score_me.sh` from this directory on the host.

<details>
<summary>Scoring criteria (spoiler — click to reveal)</summary>

| Points | Criteria |
|---|---|
| +1 | Redis is no longer reachable from the host on 8101 |
| +1 | Redis requires authentication |
| +1 | `inventory-app` `/health` still reports a working Redis connection |

> **Expected finding count: 3**

</details>
