# Challenge 25 Answer Key — Container Escape Chain

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's planted
`docker-compose.yml` gives the `app` (ops dashboard) service `DOCKER_HOST=tcp://dind:2375`,
letting its `/admin/exec` endpoint (guarded only by a hardcoded `X-Admin-Token: changeme123`
header) run arbitrary `docker` CLI commands against the `dind` sidecar's daemon — full control
over every container `dind` manages. A one-shot `planter` service already used exactly that
control plane to start `backdoor-c2`, a container with no legitimate purpose, labeled
`com.attacker.note=persistence` to simulate a prior compromise. `dind` here is a fully isolated
Docker-in-Docker daemon local to this compose project — it never touches the real host daemon.

## Step-by-step fix
1. Edit `docker-compose.yml` and remove the `DOCKER_HOST` line from the `app` service's
   `environment:` block (and its now-unnecessary `depends_on: [dind]` if you want to be
   thorough, though leaving it is harmless):
   ```yaml
   app:
     build: ./app
     container_name: ccdc-25-container-escape-chain-app
     networks:
       - labnet
     ports:
       - "8202:5000"
   ```
2. Apply with `docker compose up -d` — recreates `app` without the docker control-plane env var.
3. Remove the rogue container from the `dind` daemon directly:
   `docker compose exec dind docker rm -f backdoor-c2`
4. Confirm `app`'s legitimate functionality still works: `curl http://localhost:8202/health`
   should still return `{"status":"ok"}` — it never depended on Docker access.

## Validation
Ran `docker compose up -d --build` fresh, waited for the `planter` service to finish planting
`backdoor-c2`, then ran `./scripts/score_me.sh` against the unmodified stack — see actual output
below. Applied the fix above (`docker compose up -d` to drop `DOCKER_HOST`, then
`docker compose exec dind docker rm -f backdoor-c2`) and re-ran `score_me.sh`. Confirmed
`curl localhost:8202/health` kept returning `{"status":"ok"}` throughout. Tore down with
`docker compose down -v --rmi local` and confirmed `docker ps -a` / `docker images` were clean of
every `backdoor-c2`, `dind`, `planter`, and `app` container/image from this challenge afterward.

Note: the `/health` check (+1) legitimately passes even before the other two fixes are applied,
since it doesn't touch Docker at all — the rubric is 3 independent checks, not a strict sequence.

Actual results: unmodified stack scored `1 / 3` (only the `/health` check passed). Also confirmed
the exploit itself works as designed: `curl -X POST localhost:8202/admin/exec -H "X-Admin-Token:
changeme123" -d '{"cmd":"ps"}'` returned live `docker ps` output from the `dind` daemon showing
`backdoor-c2`, while the same request without the header returned `{"error":"unauthorized"}`.
After removing `DOCKER_HOST` from `app` (recreated via `docker compose up -d`) the score moved to
`2 / 3`; after also running `docker compose exec dind docker rm -f backdoor-c2` it reached `3 / 3`.
Reverted `docker-compose.yml` back to its shipped (vulnerable) state before finishing, then tore
down with `docker compose down -v --rmi local` and confirmed via `docker ps -a` / `docker images`
that no container or locally-built image from this challenge was left behind.
