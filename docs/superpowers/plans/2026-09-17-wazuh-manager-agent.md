# Wazuh Manager+Agent Extension Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a reusable Wazuh 5.1.0 manager+indexer+dashboard stack under `shared/wazuh/`, and wire it end-to-end into challenge `15-brute-force-detector` so the candidate investigates a live brute-force through the real Wazuh dashboard instead of grepping a static log file.

**Architecture:** A shared Compose fragment (`shared/wazuh/docker-compose.wazuh.yml`) defines the manager/indexer/dashboard, pulled into a challenge via Compose's `include:`. Each challenge adds its own `target` (victim host), an `agent` sidecar (official `wazuh/wazuh-agent` image, auto-enrolled via a small wrapper entrypoint), one or more traffic-generating containers with fixed IPs on a custom network, and an `analyst` container where the candidate writes `findings.txt`. This mirrors the role `shared/base.rb` plays for the Windows base box: centralize the shared stack definition, not a shared running instance — every challenge still owns its own `up`/`down -v` lifecycle.

**Tech Stack:** Docker Compose (`include:`, static IPs, healthchecks), official `wazuh/wazuh-manager:5.1.0`, `wazuh/wazuh-indexer:5.1.0`, `wazuh/wazuh-dashboard:5.1.0`, `wazuh/wazuh-agent:5.0.0` images, Debian-slim containers for the victim/attacker roles, bash.

**Spec:** `docs/superpowers/specs/2026-09-17-wazuh-manager-agent-design.md`

## Global Constraints

- Image versions are pinned exactly: manager/indexer/dashboard `5.1.0`, agent `5.0.0`. Do not float `:latest`.
- Only the dashboard's port is published to the host, one per challenge (`15-brute-force-detector` → `8443`). No other Wazuh port is published.
- Every challenge stays self-contained: `docker compose up -d --build` from the challenge directory brings up the whole stack; `docker compose down -v` tears it all down. Nothing persists between runs or between challenges.
- Candidates still submit conclusions to `/root/findings.txt`, scored by `score_me.sh` against known-correct values — same convention every other challenge in this repo uses. No scoring against live Wazuh API state.
- This plan covers `shared/wazuh/` and challenge `15-brute-force-detector` only. Challenges `24-multi-source-log-correlation` and `26-siem-detection-rule` are explicitly out of scope — separate follow-on plans, per the spec's scope boundary.
- Host prerequisite documented in every extended challenge's README: `sudo sysctl -w vm.max_map_count=262144`, ~4-6GB RAM budget.
- Dashboard login is the Wazuh default (`admin`/`admin`) — this repo already keeps fixed, documented lab credentials (see root `CLAUDE.md`'s credentials table), so no password-rotation step is added.

**A note on two corrections from the approved spec, made while grounding this plan against the real, current upstream Wazuh Docker deployment (`wazuh/wazuh-docker` repo, `5.1.0` branch, fetched during planning):**
1. Wazuh 5.x agents enroll via environment variables (`WAZUH_MANAGER_ENDPOINT`, `WAZUH_MANAGER_CA`, `WAZUH_REGISTRATION_PASSWORD`) read at container start, not the `agent-auth` CLI command the spec's Section A described (that's the older v4.x mechanism). The concept — target's agent enrolls automatically once the manager is healthy — is unchanged; only the exact command is corrected here.
2. The agent runs as a **sidecar container** sharing a volume with `target`, not installed inside the same container as the victim service — this lets the plan reuse the official, unmodified `wazuh/wazuh-agent` image instead of hand-installing the agent package into a custom Dockerfile.

---

### Task 1: Generate and vendor the shared Wazuh TLS cert bundle

**Files:**
- Create: `shared/wazuh/generate-certs.sh`
- Create (generated output): `shared/wazuh/config/root-ca/certs/*`, `shared/wazuh/config/wazuh_manager/certs/*`, `shared/wazuh/config/wazuh_indexer/certs/*`, `shared/wazuh/config/wazuh_dashboard/certs/*`

**Interfaces:**
- Produces: a `shared/wazuh/config/` directory tree of cert/key files at fixed paths, consumed by the volume mounts in Task 2's compose fragment.

- [ ] **Step 1: Write the cert-generation script**

```bash
mkdir -p shared/wazuh
cat > shared/wazuh/generate-certs.sh <<'SCRIPT'
#!/usr/bin/env bash
# One-time maintainer step: generates the shared Wazuh single-node TLS cert
# bundle every challenge that includes docker-compose.wazuh.yml relies on.
# Re-run to regenerate. Output is committed to git — self-signed,
# training-lab-only certs, same posture as this repo's other fixed lab
# credentials (see root CLAUDE.md's credentials table).
set -euo pipefail
cd "$(dirname "$0")"

WAZUH_VERSION="5.1.0-1"

curl -fsSL -o wazuh-certs-tool.sh "https://packages.wazuh.com/5.0/wazuh-certs-tool-${WAZUH_VERSION}.sh"
curl -fsSL -o certificates-conf.sh "https://raw.githubusercontent.com/wazuh/wazuh-docker/5.1.0/tools/utils/deployment/certificates-conf.sh"
chmod +x certificates-conf.sh

cat > config.yml <<'YAML'
nodes:
  indexer:
    - name: wazuh.indexer
      dns: "wazuh.indexer"
  manager:
    - name: wazuh.manager
      dns: "wazuh.manager"
  dashboard:
    - name: wazuh.dashboard
      dns: "wazuh.dashboard"
YAML

sudo bash certificates-conf.sh --cert --copy --priv

rm -f wazuh-certs-tool.sh certificates-conf.sh config.yml
rm -rf wazuh-certificates

echo "Certs written to shared/wazuh/config/. Review and commit that directory."
SCRIPT
chmod +x shared/wazuh/generate-certs.sh
```

- [ ] **Step 2: Run it and verify the expected files exist**

```bash
bash shared/wazuh/generate-certs.sh
find shared/wazuh/config -type f | sort
```

Expected: files under `root-ca/certs/`, `wazuh_manager/certs/`, `wazuh_indexer/certs/`, `wazuh_dashboard/certs/` — each manager/indexer/dashboard directory has a `.pem` and `-key.pem` pair, `wazuh_indexer/certs/` additionally has `admin.pem`/`admin-key.pem`, and `root-ca/certs/root-ca.pem` exists.

If `certificates-conf.sh` errors because the downloaded `wazuh-certs-tool.sh` requires `sudo`/root for chown to UID 101, that's expected — the script already invokes it via `sudo`. Confirm you can run `sudo` non-interactively or have the password ready.

- [ ] **Step 3: Commit**

```bash
git add shared/wazuh/generate-certs.sh shared/wazuh/config
git commit -m "Add shared Wazuh TLS cert bundle for the manager/indexer/dashboard stack"
```

---

### Task 2: Shared manager+indexer+dashboard compose fragment

**Files:**
- Create: `shared/wazuh/docker-compose.wazuh.yml`
- Create (scratch, not committed): a throwaway smoke-test compose file to validate the fragment in isolation

**Interfaces:**
- Consumes: `shared/wazuh/config/**` from Task 1
- Produces: services `wazuh.manager`, `wazuh.indexer`, `wazuh.dashboard` (and their named volumes) for any challenge compose file to `include:`. Manager reachable at `wazuh.manager:1517` (agent channel) and `wazuh.manager:55000` (API) from other services on the same Compose project network. Dashboard listens on container port `5601`; no host port is published by this fragment — each including challenge adds its own.

- [ ] **Step 1: Confirm Compose supports `include:`**

```bash
docker compose version
```

Expected: `v2.20.0` or newer (the `include:` top-level key requires this). If older, stop and flag it — this plan depends on it.

- [ ] **Step 2: Write the shared compose fragment**

```bash
cat > shared/wazuh/docker-compose.wazuh.yml <<'YAML'
# Wazuh 5.1.0 single-node manager+indexer+dashboard, adapted from
# https://github.com/wazuh/wazuh-docker/blob/5.1.0/single-node/docker-compose.yml
# for reuse across challenges via `include:`. Paths here resolve relative to
# THIS file's directory (shared/wazuh/), which is how Compose's `include:`
# keeps a shared fragment portable across different including projects.
#
# No ports are published except what these three services need between
# themselves. A challenge that includes this file adds a host port for the
# dashboard by re-declaring the `wazuh.dashboard` service with just a
# `ports:` key — Compose merges same-named services across an include
# boundary additively.
services:
  wazuh.manager:
    image: wazuh/wazuh-manager:5.1.0
    hostname: wazuh.manager
    restart: "no"
    depends_on:
      wazuh.indexer:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "/var/wazuh-manager/bin/wazuh-manager-control", "status"]
      interval: 15s
      timeout: 5s
      retries: 5
      start_period: 60s
    ulimits:
      memlock: { soft: -1, hard: -1 }
      nofile: { soft: 655360, hard: 655360 }
    environment:
      - WAZUH_INDEXER_HOSTS=wazuh.indexer:9200
      - WAZUH_NODE_NAME=manager
      - WAZUH_CLUSTER_NODES=wazuh.manager
      - WAZUH_CLUSTER_BIND_ADDR=wazuh.manager
      - INDEXER_USERNAME=wazuh-manager
      - INDEXER_PASSWORD=wazuh-manager
    volumes:
      - wazuh_api_configuration:/var/wazuh-manager/api/configuration
      - wazuh_etc:/var/wazuh-manager/etc
      - wazuh_logs:/var/wazuh-manager/logs
      - wazuh_queue:/var/wazuh-manager/queue
      - wazuh_var_multigroups:/var/wazuh-manager/var/multigroups
      - ./config/root-ca/certs/root-ca.pem:/var/wazuh-manager/etc/certs/root-ca.pem
      - ./config/wazuh_manager/certs/wazuh.manager.pem:/var/wazuh-manager/etc/certs/indexer-connector.pem
      - ./config/wazuh_manager/certs/wazuh.manager-key.pem:/var/wazuh-manager/etc/certs/indexer-connector-key.pem
      - ./config/wazuh_manager/certs/wazuh.manager.pem:/var/wazuh-manager/etc/certs/remoted.pem
      - ./config/wazuh_manager/certs/wazuh.manager-key.pem:/var/wazuh-manager/etc/certs/remoted-key.pem

  wazuh.indexer:
    image: wazuh/wazuh-indexer:5.1.0
    hostname: wazuh.indexer
    restart: "no"
    environment:
      - OPENSEARCH_JAVA_OPTS=-Xms1g -Xmx1g
      - bootstrap.memory_lock=true
      - network.host=0.0.0.0
      - node.name=wazuh.indexer
      - cluster.initial_cluster_manager_nodes=wazuh.indexer
      - node.max_local_storage_nodes=1
      - plugins.security.allow_default_init_securityindex=true
      - NODES_DN=CN=wazuh.indexer,OU=Wazuh,O=Wazuh,L=California,C=US
    ulimits:
      memlock: { soft: -1, hard: -1 }
      nofile: { soft: 65536, hard: 65536 }
    healthcheck:
      test: ["CMD-SHELL", "curl -fks https://localhost:9200/_plugins/_security/health | grep -q '\"status\":\"UP\"'"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s
    volumes:
      - wazuh-indexer-data:/var/lib/wazuh-indexer
      - ./config/root-ca/certs/root-ca.pem:/usr/share/wazuh-indexer/config/certs/root-ca.pem
      - ./config/wazuh_indexer/certs/wazuh.indexer-key.pem:/usr/share/wazuh-indexer/config/certs/indexer-key.pem
      - ./config/wazuh_indexer/certs/wazuh.indexer.pem:/usr/share/wazuh-indexer/config/certs/indexer.pem
      - ./config/wazuh_indexer/certs/admin.pem:/usr/share/wazuh-indexer/config/certs/admin.pem
      - ./config/wazuh_indexer/certs/admin-key.pem:/usr/share/wazuh-indexer/config/certs/admin-key.pem

  wazuh.dashboard:
    image: wazuh/wazuh-dashboard:5.1.0
    hostname: wazuh.dashboard
    restart: "no"
    healthcheck:
      test: ["CMD", "curl", "-f", "-k", "-s", "-o", "/dev/null", "https://localhost:5601/app/login"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    environment:
      - SERVER_PORT=5601
      - SERVER_HOST=0.0.0.0
      - OPENSEARCH_HOSTS=https://wazuh.indexer:9200
      - WAZUH_API_URL=https://wazuh.manager
      - DASHBOARD_USERNAME=kibanaserver
      - DASHBOARD_PASSWORD=kibanaserver
      - API_USERNAME=wazuh-wui
      - API_PASSWORD=wazuh-wui
      - SERVER_SSL_CERTIFICATE=/usr/share/wazuh-dashboard/config/certs/dashboard.pem
      - SERVER_SSL_KEY=/usr/share/wazuh-dashboard/config/certs/dashboard-key.pem
      - OPENSEARCH_SSL_CERTIFICATE_AUTHORITIES=/usr/share/wazuh-dashboard/config/certs/root-ca.pem
    volumes:
      - ./config/wazuh_dashboard/certs/wazuh.dashboard.pem:/usr/share/wazuh-dashboard/config/certs/dashboard.pem
      - ./config/wazuh_dashboard/certs/wazuh.dashboard-key.pem:/usr/share/wazuh-dashboard/config/certs/dashboard-key.pem
      - ./config/root-ca/certs/root-ca.pem:/usr/share/wazuh-dashboard/config/certs/root-ca.pem
      - wazuh-dashboard-config:/usr/share/wazuh-dashboard/config
      - wazuh-dashboard-custom:/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/custom
    depends_on:
      wazuh.indexer:
        condition: service_healthy
      wazuh.manager:
        condition: service_healthy

volumes:
  wazuh_api_configuration:
  wazuh_etc:
  wazuh_logs:
  wazuh_queue:
  wazuh_var_multigroups:
  wazuh-indexer-data:
  wazuh-dashboard-config:
  wazuh-dashboard-custom:
YAML
```

- [ ] **Step 3: Smoke-test the fragment in isolation**

```bash
mkdir -p /tmp/wazuh-fragment-smoketest
cat > /tmp/wazuh-fragment-smoketest/docker-compose.yml <<YAML
include:
  - path: $(pwd)/shared/wazuh/docker-compose.wazuh.yml
services:
  wazuh.dashboard:
    ports:
      - "8999:5601"
YAML
cd /tmp/wazuh-fragment-smoketest
docker compose config >/dev/null   # fails fast if paths/merge are wrong
docker compose up -d
docker compose ps
```

Expected: `docker compose config` succeeds (confirms the `./config/...` relative paths in the fragment resolved against `shared/wazuh/`, not the smoke-test directory). Wait for all three services to report `healthy` (can take 1-2 minutes) via repeated `docker compose ps`, then:

```bash
curl -fsk -o /dev/null -w '%{http_code}\n' https://localhost:8999/app/login
```

Expected: `200`.

- [ ] **Step 4: Tear down the smoke test**

```bash
docker compose down -v
cd -
rm -rf /tmp/wazuh-fragment-smoketest
```

- [ ] **Step 5: Commit**

```bash
git add shared/wazuh/docker-compose.wazuh.yml
git commit -m "Add shared Wazuh manager+indexer+dashboard compose fragment"
```

---

### Task 3: Wazuh agent auto-enrollment wrapper image

**Files:**
- Create: `shared/wazuh/wazuh-agent-wrapper/Dockerfile`
- Create: `shared/wazuh/wazuh-agent-wrapper/entrypoint-wrapper.sh`

**Interfaces:**
- Consumes: official `wazuh/wazuh-agent:5.0.0` image; `wazuh_etc` volume from Task 2 (read-only, for `authd.pass`); `root-ca.pem` from Task 1's cert bundle.
- Produces: a buildable image (`shared/wazuh/wazuh-agent-wrapper/`) any challenge's `agent` service can reference via `build: ../../shared/wazuh/wazuh-agent-wrapper`. Expects env vars `WAZUH_AGENT_NAME` (optional, defaults to `agent`) and a `/manager-etc` read-only mount of the manager's `wazuh_etc` volume, plus `/etc/ssl/wazuh/root-ca.pem` read-only mount of the shared root CA.

- [ ] **Step 1: Discover the base image's real entrypoint/cmd**

```bash
docker pull wazuh/wazuh-agent:5.0.0
docker inspect wazuh/wazuh-agent:5.0.0 --format '{{json .Config.Entrypoint}}'
docker inspect wazuh/wazuh-agent:5.0.0 --format '{{json .Config.Cmd}}'
```

Record both outputs exactly — they go into Step 2's `exec` line. (If `Entrypoint` is `null`, use `Cmd`'s value as the command to `exec`; if both are set, `exec` the `Entrypoint` array followed by the `Cmd` array, matching normal Docker entrypoint+cmd composition.)

- [ ] **Step 2: Write the wrapper entrypoint**

Using the actual values recorded in Step 1 in place of `<ENTRYPOINT_FROM_STEP_1>` below:

```bash
mkdir -p shared/wazuh/wazuh-agent-wrapper
cat > shared/wazuh/wazuh-agent-wrapper/entrypoint-wrapper.sh <<'SCRIPT'
#!/usr/bin/env bash
# Auto-enrolls this agent with the manager it's paired with, by reading the
# authd enrollment password the manager writes to its own wazuh_etc volume
# at first boot, instead of the manual "read it, hand-edit docker-compose.yml"
# step the upstream Wazuh docs describe. Requires:
#   - /manager-etc mounted read-only from the manager's wazuh_etc volume
#   - /etc/ssl/wazuh/root-ca.pem mounted read-only from the shared cert bundle
set -euo pipefail

AUTHD_PASS_FILE="/manager-etc/authd.pass"
for _ in $(seq 1 30); do
  [ -f "$AUTHD_PASS_FILE" ] && break
  sleep 2
done
if [ ! -f "$AUTHD_PASS_FILE" ]; then
  echo "entrypoint-wrapper: $AUTHD_PASS_FILE never appeared — is wazuh.manager healthy?" >&2
  exit 1
fi

export WAZUH_MANAGER_ENDPOINT="wazuh.manager:1517/wazuh-manager/"
export WAZUH_MANAGER_CA="/etc/ssl/wazuh/root-ca.pem"
WAZUH_REGISTRATION_PASSWORD="$(cat "$AUTHD_PASS_FILE")"
export WAZUH_REGISTRATION_PASSWORD
export WAZUH_AGENT_NAME="${WAZUH_AGENT_NAME:-agent}"

exec <ENTRYPOINT_FROM_STEP_1> "$@"
SCRIPT
chmod +x shared/wazuh/wazuh-agent-wrapper/entrypoint-wrapper.sh
```

- [ ] **Step 3: Write the Dockerfile**

```bash
cat > shared/wazuh/wazuh-agent-wrapper/Dockerfile <<'DOCKERFILE'
FROM wazuh/wazuh-agent:5.0.0
COPY entrypoint-wrapper.sh /entrypoint-wrapper.sh
ENTRYPOINT ["/entrypoint-wrapper.sh"]
DOCKERFILE
```

- [ ] **Step 4: Build it**

```bash
docker build -t wazuh-agent-wrapper:local shared/wazuh/wazuh-agent-wrapper
```

Expected: builds without error. Full enrollment behavior can't be verified standalone — it needs a live manager — so that verification happens in Task 7's end-to-end pass.

- [ ] **Step 5: Commit**

```bash
git add shared/wazuh/wazuh-agent-wrapper
git commit -m "Add Wazuh agent auto-enrollment wrapper image"
```

---

### Task 4: Challenge 15's target and attacker images

**Files:**
- Create: `challenges/15-brute-force-detector/target/Dockerfile`
- Create: `challenges/15-brute-force-detector/attacker/Dockerfile`
- Create: `challenges/15-brute-force-detector/attacker/attack.sh`

**Interfaces:**
- Produces: `target` image (Debian sshd victim, user `admin`/`S3cur3P@ss!`, password auth enabled, logs to `/var/log/auth.log`) and `attacker` image (parameterized SSH-failure generator via env vars `TARGET_HOST`, `SSH_USER`, `ATTEMPTS`, `INTERVAL_SECONDS`, `START_DELAY`), both referenced by Task 5's compose file.

- [ ] **Step 1: Write the target Dockerfile**

```bash
mkdir -p challenges/15-brute-force-detector/target
cat > challenges/15-brute-force-detector/target/Dockerfile <<'DOCKERFILE'
FROM debian:12-slim
RUN apt-get update && apt-get install -y --no-install-recommends openssh-server \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/sshd \
    && useradd -m -s /bin/bash admin \
    && echo "admin:S3cur3P@ss!" | chpasswd \
    && sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D", "-e"]
DOCKERFILE
```

- [ ] **Step 2: Build and smoke-test target standalone**

```bash
docker build -t ccdc-15-target:local challenges/15-brute-force-detector/target
docker run -d --name ccdc-15-target-test -p 2222:22 ccdc-15-target:local
sleep 2
sshpass -p 'S3cur3P@ss!' ssh -o StrictHostKeyChecking=no -p 2222 admin@localhost true
echo "exit code: $?"
```

Expected: exit code `0` (successful login), proving sshd + the `admin` account work. If `sshpass` isn't installed on the dev host, `apt-get install -y sshpass` (Linux) or equivalent first.

- [ ] **Step 3: Tear down the standalone test**

```bash
docker rm -f ccdc-15-target-test
```

- [ ] **Step 4: Write the attacker script and Dockerfile**

```bash
mkdir -p challenges/15-brute-force-detector/attacker
cat > challenges/15-brute-force-detector/attacker/attack.sh <<'SCRIPT'
#!/usr/bin/env bash
# Deterministic failed-SSH-login generator. Every parameter is required
# except START_DELAY, which defaults to 0.
set -euo pipefail
: "${TARGET_HOST:?}"
: "${SSH_USER:?}"
: "${ATTEMPTS:?}"
: "${INTERVAL_SECONDS:?}"
START_DELAY="${START_DELAY:-0}"

sleep "$START_DELAY"

for i in $(seq 1 "$ATTEMPTS"); do
  sshpass -p "wrong-password-${i}" ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=5 \
    -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no \
    "${SSH_USER}@${TARGET_HOST}" true || true
  sleep "$INTERVAL_SECONDS"
done
SCRIPT
chmod +x challenges/15-brute-force-detector/attacker/attack.sh

cat > challenges/15-brute-force-detector/attacker/Dockerfile <<'DOCKERFILE'
FROM debian:12-slim
RUN apt-get update && apt-get install -y --no-install-recommends openssh-client sshpass \
    && rm -rf /var/lib/apt/lists/*
COPY attack.sh /attack.sh
RUN chmod +x /attack.sh
ENTRYPOINT ["/attack.sh"]
DOCKERFILE
```

- [ ] **Step 5: Build and smoke-test the attacker against target on a plain Docker network**

```bash
docker network create ccdc-15-smoketest
docker rm -f ccdc-15-target-test 2>/dev/null || true
docker run -d --name ccdc-15-target-test --network ccdc-15-smoketest ccdc-15-target:local
docker build -t ccdc-15-attacker:local challenges/15-brute-force-detector/attacker
docker run --rm --network ccdc-15-smoketest \
  -e TARGET_HOST=ccdc-15-target-test -e SSH_USER=admin \
  -e ATTEMPTS=5 -e INTERVAL_SECONDS=1 \
  ccdc-15-attacker:local
docker exec ccdc-15-target-test grep -c "Failed password" /var/log/auth.log
```

Expected: the grep count prints `5`.

- [ ] **Step 6: Tear down the standalone test**

```bash
docker rm -f ccdc-15-target-test
docker network rm ccdc-15-smoketest
```

- [ ] **Step 7: Commit**

```bash
git add challenges/15-brute-force-detector/target challenges/15-brute-force-detector/attacker
git commit -m "Add challenge 15 target and attacker images"
```

---

### Task 5: Wire challenge 15's full compose stack

**Files:**
- Modify: `challenges/15-brute-force-detector/docker-compose.yml` (full rewrite)
- Create: `challenges/15-brute-force-detector/analyst/Dockerfile`
- Delete: `challenges/15-brute-force-detector/auth.log`
- Delete: `challenges/15-brute-force-detector/scripts/generate_log.py`
- Delete: `challenges/15-brute-force-detector/Dockerfile` (the old bare-container image; replaced by `target/`, `attacker/`, `analyst/`)

**Interfaces:**
- Consumes: `shared/wazuh/docker-compose.wazuh.yml` (Task 2), `shared/wazuh/wazuh-agent-wrapper` (Task 3), `target/` and `attacker/` (Task 4).
- Produces: a fully composed stack — `wazuh.manager`, `wazuh.indexer`, `wazuh.dashboard` (dashboard on host port `8443`), `target` (`10.20.15.10`), `agent` (sidecar, no fixed IP needed), `attacker-benign` (`10.20.15.20`), `attacker-malicious` (`10.20.15.99`), `analyst` — brought up together by `docker compose up -d --build` from this directory.

- [ ] **Step 1: Delete the files this rewrite obsoletes**

```bash
cd challenges/15-brute-force-detector
git rm -f auth.log scripts/generate_log.py Dockerfile
cd -
```

- [ ] **Step 2: Write the analyst Dockerfile**

```bash
mkdir -p challenges/15-brute-force-detector/analyst
cat > challenges/15-brute-force-detector/analyst/Dockerfile <<'DOCKERFILE'
FROM alpine:3.20
RUN apk add --no-cache bash curl jq
COPY scripts/score_me.sh /scripts/score_me.sh
RUN chmod +x /scripts/score_me.sh
CMD ["tail", "-f", "/dev/null"]
DOCKERFILE
```

(`scripts/score_me.sh` is rewritten in Task 6; this Dockerfile just needs the path to exist by the time you build.)

- [ ] **Step 3: Write the full compose file**

```bash
cat > challenges/15-brute-force-detector/docker-compose.yml <<'YAML'
include:
  - path: ../../shared/wazuh/docker-compose.wazuh.yml

services:
  # The shared fragment's three services don't declare a `networks:` key,
  # so without these overrides they'd fall back to an implicit `default`
  # network that doesn't exist once a custom top-level `networks:` block
  # (siem15_net, below) is defined. Re-declaring them here with just
  # `networks:` merges additively into the included definition — same
  # pattern as the `wazuh.dashboard: ports:` override — and puts every
  # service in this project unambiguously on one real network.
  wazuh.manager:
    networks:
      - siem15_net
  wazuh.indexer:
    networks:
      - siem15_net
  wazuh.dashboard:
    ports:
      - "8443:5601"
    networks:
      - siem15_net

  target:
    build: ./target
    hostname: target
    networks:
      siem15_net:
        ipv4_address: 10.20.15.10
    volumes:
      - target_varlog:/var/log

  agent:
    build: ../../shared/wazuh/wazuh-agent-wrapper
    hostname: agent
    environment:
      - WAZUH_AGENT_NAME=target
    depends_on:
      wazuh.manager:
        condition: service_healthy
      target:
        condition: service_started
    networks:
      - siem15_net
    volumes:
      - target_varlog:/var/log:ro
      - wazuh_etc:/manager-etc:ro
      - ./../../shared/wazuh/config/root-ca/certs/root-ca.pem:/etc/ssl/wazuh/root-ca.pem:ro

  attacker-benign:
    build: ./attacker
    networks:
      siem15_net:
        ipv4_address: 10.20.15.20
    environment:
      - TARGET_HOST=target
      - SSH_USER=admin
      - ATTEMPTS=5
      - INTERVAL_SECONDS=24
      - START_DELAY=10
    depends_on:
      - target

  attacker-malicious:
    build: ./attacker
    networks:
      siem15_net:
        ipv4_address: 10.20.15.99
    environment:
      - TARGET_HOST=target
      - SSH_USER=admin
      - ATTEMPTS=22
      - INTERVAL_SECONDS=4
      - START_DELAY=30
    depends_on:
      - target

  analyst:
    build: ./analyst
    networks:
      - siem15_net

networks:
  siem15_net:
    ipam:
      config:
        - subnet: 10.20.15.0/24
YAML
```

- [ ] **Step 4: Validate the compose config resolves**

```bash
cd challenges/15-brute-force-detector
docker compose config >/dev/null
cd -
```

Expected: no errors. If `include:`'s relative path resolution doesn't behave as expected (see Task 2 Step 3's note), this is where it would surface — fix path issues here before proceeding.

- [ ] **Step 5: Commit**

```bash
git add challenges/15-brute-force-detector/docker-compose.yml challenges/15-brute-force-detector/analyst
git commit -m "Wire challenge 15 into the shared Wazuh stack"
```

---

### Task 6: Rewrite challenge 15's scoring, README, and answer key

**Files:**
- Modify: `challenges/15-brute-force-detector/scripts/score_me.sh`
- Modify: `challenges/15-brute-force-detector/README.md`
- Modify: `challenges/15-brute-force-detector/ANSWER.md`

**Interfaces:**
- Consumes: the static attacker IPs fixed in Task 5 (`10.20.15.99` malicious, `10.20.15.20` benign).
- Produces: `score_me.sh` run as `docker compose exec analyst /scripts/score_me.sh`, checking `/root/findings.txt` inside the `analyst` container.

- [ ] **Step 1: Rewrite score_me.sh**

```bash
cat > challenges/15-brute-force-detector/scripts/score_me.sh <<'SCRIPT'
#!/bin/bash
# Challenge 15 - Brute-Force Detector - Scoring Engine
# Run inside the container: docker compose exec analyst /scripts/score_me.sh

FINDINGS=/root/findings.txt
SCORE=0
MAX_SCORE=3
MALICIOUS_IP="10.20.15.99"
BENIGN_IP="10.20.15.20"

echo "========================================"
echo " Brute-Force Detector Scoring Engine"
echo "========================================"
echo ""

if [ ! -f "$FINDINGS" ]; then
    echo "[X] FAIL: $FINDINGS does not exist. Write your finding there first."
    echo ""
    echo "FINAL SCORE: 0 / $MAX_SCORE"
    exit 1
fi

if grep -qx "$MALICIOUS_IP" "$FINDINGS"; then
    echo "[PASS] Malicious IP $MALICIOUS_IP flagged. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Malicious IP $MALICIOUS_IP not flagged in $FINDINGS"
fi

if grep -qx "$BENIGN_IP" "$FINDINGS"; then
    echo "[FAIL] Benign IP $BENIGN_IP was falsely flagged."
else
    echo "[PASS] Benign IP not falsely flagged. (+1)"
    SCORE=$((SCORE+1))
fi

LINES=$(grep -vc '^\s*$' "$FINDINGS")
if [ "$LINES" -eq 1 ]; then
    echo "[PASS] Findings file contains exactly one flagged IP. (+1)"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Expected exactly 1 line in $FINDINGS, found $LINES."
fi

echo ""
echo "========================================"
echo " FINAL SCORE: $SCORE / $MAX_SCORE"
echo "========================================"
SCRIPT
chmod +x challenges/15-brute-force-detector/scripts/score_me.sh
```

- [ ] **Step 2: Rewrite README.md**

```bash
cat > challenges/15-brute-force-detector/README.md <<'MARKDOWN'
# Challenge 15: Brute-Force Detector

**Category:** Log & Traffic Analysis / Detection
**Difficulty:** Medium
**Time estimate:** 40-55 minutes
**Format:** Docker (live Wazuh manager + indexer + dashboard)
**Track:** Linux/Docker/SIEM

## Scenario
`target` is a live host reporting into a real Wazuh deployment. Somewhere in
its SSH traffic is one source IP clearly brute-forcing a login. Instead of
reading a pre-baked log, you'll find it the way an analyst actually would:
through the Wazuh dashboard.

<details>
<summary><strong>Learning Objectives</strong> (spoiler — click to reveal)</summary>

- Navigate the Wazuh dashboard's Security Events view to triage live alerts
- Use `rule.level` and alert grouping to separate a real attack from
  background failed-login noise
- Confirm a finding against the underlying agent/event data, not just the
  alert summary

</details>

## Objectives
- Identify the source IP brute-forcing SSH against `target`
- Write exactly that IP to `/root/findings.txt` inside the `analyst`
  container, one line, nothing else

## Prerequisites
- `sudo sysctl -w vm.max_map_count=262144` on the Docker host (required by
  the Wazuh indexer; on Docker Desktop for Mac/Windows, set this in the
  Docker Desktop VM instead — see Docker Desktop's resources settings)
- ~4-6GB of RAM available to Docker

## Connect
| Field | Value |
|---|---|
| **Start** | `docker compose up -d --build` (first run pulls the Wazuh images — allow several minutes) |
| **Dashboard** | https://localhost:8443 (self-signed certificate — accept the browser warning) |
| **Dashboard login** | `admin` / `admin` |
| **Write findings** | `docker compose exec analyst bash`, then create `/root/findings.txt` |

## Rules of Engagement
- This is a read-only analysis exercise — there is nothing to break, only alerts to triage.

<details>
<summary><strong>Hints</strong> (try without these first — click to reveal)</summary>

- Give the stack a couple of minutes after `up` before the attack traffic
  finishes generating — the dashboard's Security Events view will start
  filling in as it does.
- Filter or sort by `rule.level` first — Wazuh's own authentication-failure
  correlation rule should separate the burst from ordinary noise without
  you needing to write anything custom.
- Once you find an alert you're confident is real, pivot on its source IP
  in the dashboard to see every event tied to it.

</details>

## Scoring
From the challenge directory on the host: `docker compose exec analyst /scripts/score_me.sh`

<details>
<summary>Scoring criteria (spoiler — click to reveal)</summary>

| Points | Criteria |
|---|---|
| +1 | Malicious IP flagged in `/root/findings.txt` |
| +1 | Benign IP not falsely flagged |
| +1 | `/root/findings.txt` contains exactly one line (no noise/duplicates) |

> **Expected finding count: 1 malicious IP out of 2 source IPs generating SSH traffic**

</details>
MARKDOWN
```

- [ ] **Step 3: Leave a placeholder marker in ANSWER.md for Task 7 to fill in**

ANSWER.md's exact wording depends on what Wazuh's default ruleset actually reports once the stack is running for real — that's confirmed empirically in Task 7, not assumed here. For now:

```bash
cat > challenges/15-brute-force-detector/ANSWER.md <<'MARKDOWN'
# Challenge 15 Answer Key — Brute-Force Detector

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

(Filled in by Task 7 after empirical validation against the live stack —
see that task for the exact rule ID/level Wazuh's default ruleset reports
and the step-by-step dashboard walkthrough.)
MARKDOWN
```

- [ ] **Step 4: Commit**

```bash
git add challenges/15-brute-force-detector/scripts/score_me.sh challenges/15-brute-force-detector/README.md challenges/15-brute-force-detector/ANSWER.md
git commit -m "Rewrite challenge 15 scoring and docs for the live Wazuh scenario"
```

---

### Task 7: End-to-end validation, threshold tuning, and final answer key

**Files:**
- Modify: `challenges/15-brute-force-detector/ANSWER.md` (fill in real content from this task's findings)
- Possibly modify: `challenges/15-brute-force-detector/docker-compose.yml` (`ATTEMPTS`/`INTERVAL_SECONDS` on the attacker services, if Wazuh's default ruleset doesn't cleanly separate malicious from benign at the values chosen in Task 5)

**Interfaces:**
- Consumes: everything from Tasks 1-6.
- Produces: a validated, working challenge — the actual deliverable of this plan.

- [ ] **Step 1: Bring the full stack up fresh**

```bash
cd challenges/15-brute-force-detector
docker compose down -v 2>/dev/null || true
docker compose up -d --build
```

- [ ] **Step 2: Wait for the stack to become healthy**

```bash
watch -n 5 docker compose ps
```

Expected: `wazuh.manager`, `wazuh.indexer`, `wazuh.dashboard` all report `healthy`. This can take 1-3 minutes. Ctrl-C once healthy.

- [ ] **Step 3: Confirm the agent enrolled and shows active**

```bash
docker compose logs agent --tail 50
docker compose exec wazuh.manager /var/wazuh-manager/bin/agent_control -l
```

Expected: the agent log shows a successful connection to the manager (no repeated connection-refused errors), and `agent_control -l` lists an agent named `target` with status `Active`. If it's not active after a couple minutes, check `docker compose logs agent` for the specific failure (common causes: `authd.pass` read before the manager finished writing it — the wrapper's retry loop from Task 3 should cover this, but if not, increase the retry count/sleep there).

- [ ] **Step 4: Let the attack traffic finish, then inspect the manager's own alerts**

```bash
sleep 180   # covers attacker-malicious's ~30s start delay + ~22*4s of attempts + margin
docker compose exec wazuh.manager sh -c \
  "jq -c 'select(.data.srcip==\"10.20.15.99\")' /var/wazuh-manager/logs/alerts/alerts.json | tail -5"
docker compose exec wazuh.manager sh -c \
  "jq -c 'select(.data.srcip==\"10.20.15.20\")' /var/wazuh-manager/logs/alerts/alerts.json | tail -5"
```

Expected: `10.20.15.99` shows one or more alerts at a meaningfully higher `rule.level` than anything from `10.20.15.20` — specifically, a correlation/frequency rule (Wazuh's default `sshd: multiple authentication failures`-style rule) firing for `.99` and not for `.20`. Record the exact `rule.id`, `rule.level`, and `rule.description` you observe — they go into ANSWER.md in Step 6.

If both IPs trigger the same rule, or neither crosses into a distinctly higher level, the benign/malicious volumes in Task 5's compose file are too close together for Wazuh's default threshold to discriminate. Adjust `attacker-malicious`'s `ATTEMPTS`/`INTERVAL_SECONDS` (more attempts, shorter interval) and/or `attacker-benign`'s (fewer attempts, longer interval) in `docker-compose.yml`, then:

```bash
docker compose up -d --build attacker-benign attacker-malicious
```

and repeat this step until the separation is clean.

- [ ] **Step 5: Confirm scoring end-to-end**

```bash
docker compose exec analyst sh -c "echo '10.20.15.99' > /root/findings.txt"
docker compose exec analyst /scripts/score_me.sh
```

Expected: `3 / 3`. Then confirm the negative case:

```bash
docker compose exec analyst sh -c "echo '10.20.15.20' > /root/findings.txt"
docker compose exec analyst /scripts/score_me.sh
```

Expected: `1 / 3` (malicious IP missing, benign falsely flagged, but still exactly one line).

- [ ] **Step 6: Fill in the real ANSWER.md**

Using the `rule.id`/`rule.level`/`rule.description` recorded in Step 4:

```bash
cat > challenges/15-brute-force-detector/ANSWER.md <<MARKDOWN
# Challenge 15 Answer Key — Brute-Force Detector

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's planted
\`target\` is a live Debian host running real sshd with one account
(\`admin\`). Two containers generate real SSH traffic against it on a fixed
subnet (\`10.20.15.0/24\`):
- \`attacker-benign\` (\`10.20.15.20\`) — a handful of scattered failed logins,
  within Wazuh's default noise tolerance.
- \`attacker-malicious\` (\`10.20.15.99\`) — a fast burst of failed logins that
  crosses Wazuh's default authentication-failure correlation threshold.

## Step-by-step fix
1. Open the dashboard at https://localhost:8443, log in as \`admin\`/\`admin\`.
2. Go to Security Events (or Threat Hunting, depending on dashboard version)
   and sort/filter by \`rule.level\`.
3. [FILL IN FROM TASK 7 STEP 4: the exact rule id/level/description observed,
   and how it visibly separates .99 from .20 in the dashboard]
4. Pivot on \`10.20.15.99\` to confirm every alert tied to it is the same
   fast burst, inside a tight time window, distinct from \`10.20.15.20\`'s
   scattered low-rate noise.
5. \`docker compose exec analyst bash\`, then:
   \`\`\`
   echo "10.20.15.99" > /root/findings.txt
   \`\`\`

## Validation
Ran \`docker compose up -d --build\` fresh, confirmed \`score_me.sh\` reports
\`0 / 3\` with no \`findings.txt\` present. Confirmed the agent enrolled and
showed \`Active\` via \`agent_control -l\`. Confirmed Wazuh's default ruleset
alerts on \`10.20.15.99\` at [FILL IN LEVEL] and not on \`10.20.15.20\` at the
same level. Wrote \`10.20.15.99\` to \`/root/findings.txt\` and confirmed
\`score_me.sh\` reports \`3 / 3\`. Confirmed the negative case (wrong IP)
reports \`1 / 3\`. Torn down with \`docker compose down -v\` afterward.
MARKDOWN
```

Replace the two `[FILL IN ...]` markers with what you actually observed in Step 4 before committing — do not leave them in.

- [ ] **Step 7: Tear down**

```bash
docker compose down -v
cd -
```

- [ ] **Step 8: Commit**

```bash
git add challenges/15-brute-force-detector/ANSWER.md
git add challenges/15-brute-force-detector/docker-compose.yml   # if Step 4 required tuning
git commit -m "Validate challenge 15 end-to-end against the live Wazuh stack"
```

---

### Task 8: Verify existing packaging flow against the multi-service stack

**Files:** none modified — this task validates that `scripts/package-challenge.sh` (already in the repo) handles a challenge whose compose file pulls in a shared `include:`d fragment, without needing any changes.

**Interfaces:**
- Consumes: `challenges/15-brute-force-detector/` in its final state from Tasks 1-7.
- Produces: confirmation (or a bug report) that `--offline` packaging bundles every image the merged compose config references, including the ones that only exist because of the shared fragment.

- [ ] **Step 1: Run the candidate offline bundle**

```bash
cd /home/tavern/Projects/CCDC-Practice
./scripts/package-challenge.sh challenges/15-brute-force-detector --bundle candidate --offline
```

- [ ] **Step 2: Confirm every expected image landed in the bundle**

```bash
unzip -l dist/15-brute-force-detector-candidate.zip | grep -E '\.tar$|images/'
```

Expected: images for `wazuh.manager` (`wazuh/wazuh-manager:5.1.0`), `wazuh.indexer` (`wazuh/wazuh-indexer:5.1.0`), `wazuh.dashboard` (`wazuh/wazuh-dashboard:5.1.0`), plus the locally-built `target`, `attacker` (used by both attacker services), `agent` (the wrapper), and `analyst` images. If any are missing, `package-challenge.sh`'s image-discovery step is reading services directly rather than resolving `docker compose config` (which flattens `include:`) — that's a real bug in the packaging script to fix, not something to work around per-challenge.

- [ ] **Step 3: Confirm the candidate bundle excludes the answer key**

```bash
unzip -l dist/15-brute-force-detector-candidate.zip | grep -E 'ANSWER\.md|score_me'
```

Expected: `ANSWER.md` and `scripts/score_me.sh` are absent from the candidate bundle (same exclusion rule as every other challenge), while `docker-compose.yml`, the Dockerfiles, and `shared/wazuh/`'s files needed to build/run are present.

- [ ] **Step 4: Clean up**

```bash
rm -f dist/15-brute-force-detector-candidate.zip dist/15-brute-force-detector-instructor.zip
```

No commit — this task produces no file changes unless Step 2 surfaces a real bug in `package-challenge.sh`, in which case fix it there and commit that fix separately with its own message describing the bug.
