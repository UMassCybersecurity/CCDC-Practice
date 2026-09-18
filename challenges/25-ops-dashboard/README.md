# Challenge 25: The Ops Dashboard

**Category:** Container Security / Access Review
**Difficulty:** Hard
**Time estimate:** 45-60 minutes
**Format:** Docker
**Track:** Linux/Docker/SIEM

## Scenario
WidgetCorp's small "ops dashboard" container was wired up with direct access to a
Docker control plane "temporarily, to let it restart its own sibling containers."
Nobody ever removed that access. Anyone who can reach the dashboard's admin endpoint
can now issue arbitrary Docker commands — and someone already has. There's a
container running that nobody on the team recognizes.

## Objectives
- Remove the ops dashboard's (`app`) ability to reach the Docker control plane
- Remove the rogue container that was planted through that access
- Keep the dashboard's legitimate `/health` endpoint working

## Connect
| Field | Value |
|---|---|
| **Start** | `docker compose up -d --build` (from this directory) |
| **App** | http://localhost:8202/health |
| **Edit** | `docker-compose.yml` — remove the app's Docker control-plane wiring, then `docker compose up -d` to apply |

## Rules of Engagement
- This lab runs an isolated, self-contained `docker:dind` (Docker-in-Docker) daemon
  as the "victim" control plane — it is fully sandboxed inside this challenge's own
  compose project and has no connection to your actual host Docker daemon. It is
  safe to poke at, restart, or tear down without any risk beyond this challenge stack.
- The `app` service's `/health` endpoint must keep returning 200 with `"status":"ok"` after your fix.

## Scoring
Run `./scripts/score_me.sh` from this directory on the host.

<details>
<summary>Scoring criteria (spoiler — click to reveal)</summary>

| Points | Criteria |
|---|---|
| +1 | `app` no longer has Docker control-plane access (`DOCKER_HOST` wiring removed) |
| +1 | The rogue `backdoor-c2` container has been removed from the `dind` daemon |
| +1 | `app`'s `/health` endpoint still responds correctly |

> **Expected finding count: 3**

</details>
