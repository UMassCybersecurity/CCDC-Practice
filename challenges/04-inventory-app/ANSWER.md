# Challenge 04 Answer Key — The Inventory App

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## Learning Objectives
- Add authentication to a datastore that ships with none by default
- Stop publishing an internal service to the host network
- Wire a new credential through to a dependent application via environment variables
- Verify a fix doesn't break the service that depends on it

## Hints
- `redis-server --requirepass <password>` is the quickest way to add auth to the `redis` service's `command:`.
- The app needs that same password passed in via an environment variable so it can still connect.
- Dropping the `ports:` mapping on the `redis` service removes host access entirely — containers on the same compose network can still reach it by service name.
- `docker compose up -d` picks up compose file changes without a rebuild.

## Scoring breakdown
| Points | Criteria |
|---|---|
| +1 | Redis is no longer reachable from the host on 8101 |
| +1 | Redis requires authentication |
| +1 | `inventory-app` `/health` still reports a working Redis connection |

## What's broken / planted
`docker-compose.yml` publishes `redis` on host port 8101 with no `requirepass`, so any host process (or anyone who can reach the box) has unauthenticated read/write access to the datastore. `app` connects to it with no credential.

## Step-by-step fix
Edit `docker-compose.yml`:
```yaml
services:
  redis:
    image: redis:7-alpine
    command: ["redis-server", "--requirepass", "S3cur3R3dis!"]

  app:
    build: ./app
    environment:
      REDIS_HOST: redis
      REDIS_PORT: 6379
      REDIS_PASSWORD: S3cur3R3dis!
    ports:
      - "8102:5000"
    depends_on:
      - redis
```
(Removed the `redis` service's `ports:` block, added `--requirepass` to its command, and added `REDIS_PASSWORD` to `app`'s environment so `app.py` — which already reads `REDIS_PASSWORD` — can authenticate.)

Apply with `docker compose up -d` (recreates both containers; no rebuild needed since only compose config changed).

## Validation
Ran a fresh `docker compose up -d --build` on 2026-08-14, confirmed `score_me.sh` showed 1/3 (only the app-health check passed, since it wasn't using a password yet) against the shipped (broken) compose file. Applied the fix above and ran `docker compose up -d` and confirmed `score_me.sh` then showed 3/3. Torn down with `docker compose down -v`.
