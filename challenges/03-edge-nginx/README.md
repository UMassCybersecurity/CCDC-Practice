# Challenge 03: The Edge Proxy

**Category:** Service Hardening & Secure Configuration
**Difficulty:** Easy
**Time estimate:** 20-30 minutes
**Format:** Docker
**Track:** Linux/Docker/SIEM

## Scenario
WidgetCorp's edge nginx was stood up in a hurry to front the internal "backend" service. Someone dropped a self-signed certificate in place for "later" and never finished the job — the site is still plain HTTP, and there's no redirect to force clients onto an encrypted connection. Security wants this fixed before the next audit.

## Objectives
- Serve the backend over HTTPS on port 443 using the provided certificate
- Redirect all plain HTTP traffic to HTTPS
- Restrict TLS to TLSv1.2 and TLSv1.3 only
- Keep the backend reachable throughout

## Connect
| Field | Value |
|---|---|
| **Start** | `docker compose up -d --build` (from this directory) |
| **HTTP** | http://localhost:8100 |
| **HTTPS** | https://localhost:8143 |
| **Edit** | `edge/default.conf` (the `edge/` directory is mounted live into the `edge` container at `/etc/nginx/conf.d` — edit and `docker compose exec edge nginx -s reload`, no rebuild needed) |
| **Certificate** | `certs/server.crt` / `certs/server.key` (already generated, self-signed, valid 10 years) |

## Rules of Engagement
- Don't take the backend offline — it must keep responding through both the fix and afterward.

## Scoring
Run `./scripts/score_me.sh` from this directory on the host.

**3 points total.** Full breakdown is in ANSWER.md.
