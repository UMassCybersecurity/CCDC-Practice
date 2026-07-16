# Challenge 01: Find and Remove Persistence

**Scenario:** Your organization's domain controller was compromised last weekend. The incident response team removed the initial malware, but they suspect the attacker left multiple persistence mechanisms behind. Your job: find and remove **ALL** of them.

---

## Objectives
- Identify all persistence mechanisms the attacker planted
- Remove them without breaking legitimate services
- Document what you found *(attacker's username, methods used, etc.)*

---

## Connect
| Field | Value |
|---|---|
| **RDP To** | 192.168.56.10 |
| **Username** | CORP\jsmith |
| **Password** | Welcome1! |

---

## Hints *(try without these first)*
- Check scheduled tasks
- Check for unauthorized users *(especially in privileged groups)*
- Check services
- Check WMI subscriptions
- Check startup locations *(Run keys, startup folder)*
- Check for rogue GPOs

---

## Scoring

| Points | Criteria |
|---|---|
| +10 | Found rogue user account |
| +10 | Found malicious scheduled task |
| +10 | Found malicious service |
| +10 | Found WMI persistence |
| +10 | Found registry run key |
| +10 | Found rogue GPO |
| -20 | Broke AD DS service |
| -20 | Broke DNS |
| -10 | Removed legitimate accounts |

> **Expected persistence count: 6**
