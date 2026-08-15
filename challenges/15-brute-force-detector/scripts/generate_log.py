#!/usr/bin/env python3
"""Deterministic generator for auth.log — run once, commit the output."""
import random

random.seed(42)
lines = []
pid = 30000


def ts(day, h, m, s):
    return f"Mar {day:02d} {h:02d}:{m:02d}:{s:02d}"


def failed(day, h, m, s, user, ip):
    global pid
    pid += 1
    lines.append(f"{ts(day, h, m, s)} prod-app03 sshd[{pid}]: Failed password for {user} from {ip} port {random.randint(30000, 60000)} ssh2")


def accepted(day, h, m, s, user, ip):
    global pid
    pid += 1
    lines.append(f"{ts(day, h, m, s)} prod-app03 sshd[{pid}]: Accepted password for {user} from {ip} port {random.randint(30000, 60000)} ssh2")


def cron(day, h, m, s):
    global pid
    pid += 1
    lines.append(f"{ts(day, h, m, s)} prod-app03 CRON[{pid}]: (root) CMD (/usr/lib/php/sessionclean)")


# Benign noise, scattered across the day, never bursty — must stay under threshold
benign = {
    "203.0.113.10": ("bob", 4),
    "203.0.113.11": ("carol", 2),
    "192.0.2.5": ("root", 6),
    "192.0.2.6": ("test", 3),
    "192.0.2.7": ("admin", 5),
}
for ip, (user, count) in benign.items():
    for _ in range(count):
        failed(14, random.randint(0, 22), random.randint(0, 59), random.randint(0, 59), user, ip)

accepted(14, 6, 5, 12, "jsmith", "10.0.5.44")
accepted(14, 12, 30, 2, "svc-deploy", "10.0.5.12")
for h in [1, 5, 9, 13, 17, 21]:
    cron(14, h, 0, 1)

# Malicious burst: 22 failed attempts against admin, 12s apart — well past threshold
mal_ip = "198.51.100.99"
t = 0
for _ in range(22):
    failed(15, 3, t // 60, t % 60, "admin", mal_ip)
    t += 12

lines.sort(key=lambda line: (line.split()[0], line.split()[1]))
with open("auth.log", "w") as f:
    f.write("\n".join(lines) + "\n")
print(f"{len(lines)} lines written")
