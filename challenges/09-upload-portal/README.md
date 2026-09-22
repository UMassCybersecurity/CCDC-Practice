# Challenge 09: The Upload Portal

**Category:** Persistence & Backdoor Hunting
**Difficulty:** Easy
**Time estimate:** 20-30 minutes
**Format:** Docker
**Track:** Linux/Docker/SIEM

## Scenario
WidgetCorp's marketing site takes public file uploads for the "share your widget photo" contest. Someone on the security mailing list noticed an odd filename in the web server's access patterns and asked you to check the uploads directory before this spreads.

## Objectives
- Find and remove whatever doesn't belong in `uploads/`
- Keep the company site and the legitimate uploaded file intact and reachable

## Connect
| Field | Value |
|---|---|
| **Start (find & remove, default)** | `docker compose up -d --build` |
| **Start (attack-practice variant)** | `VARIANT=redteam docker compose up -d --build` — same upload vulnerability, nothing pre-planted; exploit it yourself, then switch back to the default variant to practice defending it. Ungraded, not run through `score_me.sh`. |
| **Site** | http://localhost:8201/ |
| **Shell in** | `docker compose exec web sh` |

## Rules of Engagement
- The site (`/`) and the legitimate upload (`/uploads/welcome.txt`) must keep returning `200` throughout.

## Scoring
Run `./scripts/score_me.sh` from the challenge directory on the host.

**3 points, plus 1 bonus point.** Full breakdown is in ANSWER.md.
