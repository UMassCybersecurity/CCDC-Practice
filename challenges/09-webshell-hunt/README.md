# Challenge 09: Webshell Hunt

**Category:** Persistence & Backdoor Hunting
**Difficulty:** Easy
**Time estimate:** 20-30 minutes
**Format:** Docker

## Scenario
WidgetCorp's marketing site takes public file uploads for the "share your widget photo" contest. Someone on the security mailing list noticed an odd filename in the web server's access patterns and asked you to check the uploads directory before this spreads.

<details>
<summary><strong>Learning Objectives</strong> (spoiler — click to reveal)</summary>

- Recognize a minimal PHP command-execution backdoor disguised as a legitimate uploaded file
- Practice web-root triage: distinguishing planted files from real user uploads
- Remediate without deleting legitimate site content

</details>

## Objectives
- Find and remove the planted backdoor file from `uploads/`
- Keep the company site and the legitimate uploaded file intact and reachable

## Connect
| Field | Value |
|---|---|
| **Start** | `docker compose up -d --build` |
| **Site** | http://localhost:8201/ |
| **Shell in** | `docker compose exec web sh` |

## Rules of Engagement
- The site (`/`) and the legitimate upload (`/uploads/welcome.txt`) must keep returning `200` throughout.

<details>
<summary><strong>Hints</strong> (try without these first — click to reveal)</summary>

- Not every file under `uploads/` was actually uploaded by a real user.
- A PHP file that does nothing but call `system()` on a POST parameter isn't a thumbnail generator.
- `grep -r "system(" uploads/` is a fast way to triage a whole directory.

</details>

## Scoring
Run `./scripts/score_me.sh` from the challenge directory on the host.

<details>
<summary>Scoring criteria (spoiler — click to reveal)</summary>

| Points | Criteria |
|---|---|
| +1 | No command-execution backdoor remains under the web root |
| +1 | Company site (`/`) still returns 200 |
| +1 | Legitimate uploaded file still returns 200 |

> **Expected finding count: 1**

</details>
