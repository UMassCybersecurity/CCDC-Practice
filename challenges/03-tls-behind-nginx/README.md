# Challenge 03: TLS Behind Nginx

**Category:** Service Hardening & Secure Configuration
**Difficulty:** Easy
**Time estimate:** 20-30 minutes
**Format:** Docker

## Scenario
WidgetCorp's edge nginx was stood up in a hurry to front the internal "backend" service. Someone dropped a self-signed certificate in place for "later" and never finished the job — the site is still plain HTTP, and there's no redirect to force clients onto an encrypted connection. Security wants this fixed before the next audit.

## Learning Objectives
- Configure nginx to terminate TLS using an existing certificate/key pair
- Enforce an HTTP → HTTPS redirect
- Restrict `ssl_protocols` to modern, non-deprecated TLS versions
- Edit a live nginx config and reload without downtime

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

## Hints *(try without these first)*
- The certificate and key are already on disk — you just need to point nginx at them.
- `listen 443 ssl;` plus `ssl_certificate` / `ssl_certificate_key` directives are all a minimal TLS server block needs.
- A `return 301 https://...` block on the port-80 server is the simplest redirect.
- `ssl_protocols TLSv1.2 TLSv1.3;` disables the deprecated versions.
- After editing `edge/default.conf`, run `docker compose exec edge nginx -s reload` to apply it without restarting the container.

## Scoring
Run `./scripts/score_me.sh` from this directory on the host.

| Points | Criteria |
|---|---|
| +1 | HTTPS on port 8143 serves the backend |
| +1 | Plain HTTP on port 8100 redirects (3xx) |
| +1 | `ssl_protocols` restricted to TLSv1.2 and TLSv1.3 |

> **Expected finding count: 3**
