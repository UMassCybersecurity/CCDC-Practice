# Challenge 25: The Ops Dashboard

**Category:** Container Security / Access Review
**Difficulty:** Hard
**Time estimate:** 45-60 minutes
**Format:** Docker
**Track:** Linux/Docker/SIEM

## Scenario
WidgetCorp's small "ops dashboard" container has more reach into the surrounding
infrastructure than it should — wired up "temporarily" months ago and never revisited.
Something is running now that nobody on the team recognizes.

## Objectives
- Cut off whatever excess access the ops dashboard (`app`) has into the infrastructure around it
- Clean up whatever that access was used for
- Keep the dashboard's legitimate `/health` endpoint working

## Connect
| Field | Value |
|---|---|
| **Start** | `docker compose up -d --build` (from this directory) |
| **App** | http://localhost:8202/health |
| **Edit** | `docker-compose.yml`, then `docker compose up -d` to apply your fix |

## Rules of Engagement
- This lab's backing infrastructure is fully sandboxed inside this challenge's own
  compose project and has no connection to your actual host system — safe to poke at,
  restart, or tear down without any risk beyond this challenge stack.
- The `app` service's `/health` endpoint must keep returning 200 with `"status":"ok"` after your fix.

## Scoring
Run `./scripts/score_me.sh` from this directory on the host.

**3 points total.** Full breakdown is in ANSWER.md.
