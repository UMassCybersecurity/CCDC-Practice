# Challenge 25: Container Escape Chain

**Category:** Container Security / Privilege Escalation
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

<details>
<summary><strong>Learning Objectives</strong> (spoiler — click to reveal)</summary>

- Recognize Docker-socket / Docker-control-plane exposure as a container-escape primitive
- Understand why "just for admin convenience" access to a Docker daemon is equivalent to root on every container it manages
- Identify and remove rogue containers planted via a compromised control plane
- Remediate the exposure without breaking the legitimate service that depends on the same stack

</details>

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

<details>
<summary><strong>Hints</strong> (try without these first — click to reveal)</summary>

- `docker compose exec app printenv DOCKER_HOST` shows exactly what the dashboard container can reach.
- The rogue container isn't running on your host — it's running on the `dind` service's own daemon. `docker compose exec dind docker ps` looks inside it.
- Removing the app's access and removing the rogue container are two separate steps — fixing one doesn't fix the other.
- `docker compose up -d` picks up compose file changes without a rebuild.

</details>

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
