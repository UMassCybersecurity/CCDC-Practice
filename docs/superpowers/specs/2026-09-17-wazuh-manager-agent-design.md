# Wazuh manager+agent extension — design

## Purpose

Extend a subset of the Linux/SIEM-track challenges to run a real Wazuh
manager + indexer + dashboard + agent stack, so candidates investigate a
live scenario through the actual product (Wazuh, matching the org's real
SIEM) instead of reading a pre-baked static log/alert file.

This is **separate from the async prescreening track** decided earlier
(challenges 13/09/18/19 for prescreening, kept Docker-first and
low-friction). This work targets deeper/later training content, where
heavier setup — real RAM/CPU budget, host `sysctl` tuning, longer spin-up —
is an acceptable trade for authenticity. Challenge 13 (log-triage) is
explicitly excluded from this effort since it's a locked prescreening pick.

## Target challenges

- `15-brute-force-detector`
- `24-multi-source-log-correlation`
- `26-siem-detection-rule`

All three are currently Docker-format challenges that mount a static log
file into a bare container for `grep`/`jq` analysis. Each becomes a live
scenario investigated through a real Wazuh manager+dashboard.

## Architecture

### Shared stack

```
shared/wazuh/
  docker-compose.wazuh.yml   # manager + indexer + dashboard services,
                              # shared network, healthchecks
  config/                     # ossec.conf overlay, indexer/dashboard
                              # certs & config
  generate-certs.sh           # one-shot TLS bootstrap between Wazuh's
                              # own components
  agent-enroll.sh             # shared entrypoint helper for target containers
```

This plays the same role `shared/base.rb` plays for the Windows base box:
one place to define and update the manager/indexer/dashboard config. It
does **not** introduce a persistently-running shared instance — each
challenge includes the fragment into its own `docker-compose.yml` via
Compose's `include:` directive and owns its full stack lifecycle
(`docker compose up -d --build` / `docker compose down -v` from the
challenge directory, nothing persists between runs or between challenges).

### Per-challenge composition

Each of 15/24/26's `docker-compose.yml`:
1. `include:`s `shared/wazuh/docker-compose.wazuh.yml`
2. Defines a `target` service — the victim host running the scenario's
   real service (sshd, web server, etc.), with a Wazuh agent installed
   and enrolled to the manager
3. Defines a `simulator` service — replays the scenario's scripted events
   against `target` once the agent is confirmed active

### Agent enrollment

`target`'s entrypoint:
1. `depends_on: wazuh-manager: condition: service_healthy`
2. Runs `agent-auth -m wazuh-manager` to register and obtain an agent key
3. Starts `wazuh-agentd`

Enrollment logic lives once in `shared/wazuh/agent-enroll.sh`, sourced by
each challenge's target `Dockerfile`/entrypoint rather than re-implemented
per challenge.

### Networking

All inter-service traffic (manager ↔ indexer ↔ dashboard ↔ target) stays
on the Compose-internal network, addressed by service name. Only the
dashboard's port (443) is published to the host, on a **distinct port per
challenge** to avoid collisions if more than one stack happens to be up:

| Challenge | Dashboard port |
|---|---|
| 15-brute-force-detector | 8443 |
| 24-multi-source-log-correlation | 8543 |
| 26-siem-detection-rule | 8643 |

### Event generation (determinism)

A live agent means real logs and real Wazuh rules firing off real
activity. An unscripted "attacker" would make each run's alert set
non-reproducible, which breaks scoring — `score_me.sh` and the answer key
need a fixed expected outcome. Each challenge's `simulator` service
replays a **fixed, scripted sequence** of real actions against `target`
(real SSH attempts, real HTTP requests, etc. depending on the challenge) —
the same underlying idea as today's canned `auth.log`/`alerts.json`,
except the events are now generated live and detected by Wazuh's actual
ruleset instead of being pre-authored as static findings. Candidates read
results through the dashboard/manager, not the simulator.

### Scoring

Unchanged pattern: candidates write conclusions to `/root/findings.txt`
(or equivalent), `score_me.sh` checks that file against known-correct
values, same as every other challenge. No new scoring mechanism tied to
live Wazuh API state — that would add fragility (timing, alert
deduplication, indexer lag) without a clear benefit over the existing
convention.

## Prerequisites & resource budget

Wazuh's indexer requires `vm.max_map_count=262144` on the Docker host —
this cannot be set from inside a container. Each extended challenge's
README gets a prerequisites section with:
- `sudo sysctl -w vm.max_map_count=262144` (Linux) and the Docker Desktop
  equivalent (Mac/Windows)
- A stated RAM budget (~4-6GB for manager+indexer+dashboard+target)

This is consistent with the "deeper training, heavier setup is
acceptable" purpose — not appropriate for the prescreening track.

## Packaging

Reuses the existing `--offline` path in `scripts/package-challenge.sh`
unchanged. It already `docker save`s whatever images a challenge's
compose config references (via `docker compose config`), which covers a
multi-service stack (manager/indexer/dashboard/target/simulator) the same
way it covers any single-service challenge today. No new packaging
mechanism required.

## Testing & validation

Same standard the repo already holds every challenge to: build fresh,
confirm `score_me.sh` fails pre-fix and passes post-fix, run the full
answer end-to-end once before considering the challenge done. For the
shared stack specifically, validation also confirms:
- `docker compose up -d --build` reaches a healthy manager/indexer/dashboard
- The target's agent shows as `active` in the dashboard
- The simulator's scripted events produce the expected Wazuh alerts

## Scope boundary

This spec covers the shared subsystem (`shared/wazuh/`) and the contract a
challenge implements to plug into it: compose `include`, target+agent
pattern, simulator convention, port assignment, prerequisites, packaging.

It does **not** fully design the new scenario content for 15, 24, and 26
individually — what exact events the simulator replays, which Wazuh rule
IDs matter, what the rewritten scoring rubric looks like. Fully speccing
three rewritten challenge scenarios in one document would bloat this past
what the shared infrastructure actually needs. Each challenge's content
rewrite is a smaller follow-on implementation pass, referencing this
shared contract, done one challenge at a time.
