#!/usr/bin/env python3
"""Deterministic generator for ../auth.log — run once, commit the output.
Stdlib only (no scapy needed here, unlike challenge 14's pcap generator).

The real incident (45.33.12.201 / svc-deploy, 03:14:22, zero prior failed
attempts, IP appears nowhere else) is appended last with fixed values and
never touched by the noise generation above it — only noise placement uses
the seeded RNG, so the answer stays stable across regenerations."""
import random

random.seed(42)

HOST = "prod-app07"
pid = 40000


def next_pid():
    global pid
    pid += 1
    return pid


def ts(h, m, s=0):
    return f"Mar 14 {h:02d}:{m:02d}:{s:02d}"


def accepted(h, m, user, ip, s=0):
    return (h * 60 + m, f"{ts(h, m, s)} {HOST} sshd[{next_pid()}]: Accepted password for {user} from {ip} port {random.randint(30000, 65000)} ssh2")


def failed(h, m, user, ip, s=0):
    return (h * 60 + m, f"{ts(h, m, s)} {HOST} sshd[{next_pid()}]: Failed password for {user} from {ip} port {random.randint(30000, 65000)} ssh2")


def invalid_failed(h, m, user, ip, s=0):
    return (h * 60 + m, f"{ts(h, m, s)} {HOST} sshd[{next_pid()}]: Failed password for invalid user {user} from {ip} port {random.randint(30000, 65000)} ssh2")


def cron(h):
    return (h * 60, f"{ts(h, 0, 1)} {HOST} CRON[{next_pid()}]: (root) CMD (/usr/lib/php/sessionclean)")


def logrotate(h):
    return (h * 60 + 2, f"{ts(h, 2, 0)} {HOST} CRON[{next_pid()}]: (root) CMD (/usr/sbin/logrotate /etc/logrotate.conf)")


events = []

# --- CRON noise: every hour, plus logrotate every 6 hours
for h in range(24):
    events.append(cron(h))
for h in [0, 6, 12, 18]:
    events.append(logrotate(h))

# --- Employees: internal LAN, business-hours regulars, some with a SAFE off-hours login (IP recurs)
employees_internal = [
    ("jsmith", "10.0.4.15"), ("mgarcia", "10.0.4.22"), ("achen", "10.0.4.31"),
    ("bpatel", "10.0.4.44"), ("kwilson", "10.0.4.58"), ("drossi", "10.0.4.63"),
    ("nkumar", "10.0.4.70"), ("ssingh", "10.0.4.81"), ("tobrien", "10.0.4.92"),
    ("lferreira", "10.0.4.101"), ("hyoon", "10.0.4.114"), ("mwalsh", "10.0.4.129"),
]
for user, ip in employees_internal:
    n_logins = random.randint(2, 4)
    hours_used = random.sample(range(8, 18), n_logins)
    for h in hours_used:
        m = random.randint(0, 59)
        events.append(accepted(h, m, user, ip))

# Give a few employees ALSO a legitimate off-hours login (on-call) -- safe because
# their IP already has >=1 other appearance above, so count[ip] > 1.
for user, ip in [("mgarcia", "10.0.4.22"), ("drossi", "10.0.4.63"), ("nkumar", "10.0.4.70")]:
    h = random.choice([21, 22, 23, 1, 2, 5, 6])
    m = random.randint(0, 59)
    events.append(accepted(h, m, user, ip))

# --- Remote/VPN employees, occasional off-hours access (again, IP recurs -> safe)
vpn_employees = [
    ("rgarrett", "172.16.50.11"), ("cwu", "172.16.50.24"), ("apetrov", "172.16.50.37"),
]
for user, ip in vpn_employees:
    for _ in range(random.randint(2, 3)):
        h = random.choice(list(range(7, 20)) + [20, 21, 22, 23, 0, 1, 6])
        m = random.randint(0, 59)
        events.append(accepted(h, m, user, ip))

# --- twong: a typo'd login (2 failed then accepted), plus a second later accepted -- existing pattern, kept
tw_ip = "203.0.113.50"
h0, m0 = 9, 38
events.append(failed(h0, m0, "twong", tw_ip)); m0 += 1
events.append(failed(h0, m0, "twong", tw_ip)); m0 += 1
events.append(accepted(h0, m0, "twong", tw_ip))
events.append(accepted(15, 10, "twong", tw_ip))

# --- Scanner/bot IPs: many failed attempts scattered any time of day, never succeed, always >1 occurrence
scanner_ips = [
    "198.51.100.9", "198.51.100.44", "198.51.100.180",
    "192.0.2.77", "192.0.2.15", "192.0.2.201",
    "203.0.113.5", "203.0.113.77", "203.0.113.140",
    "194.55.187.20", "89.248.165.32", "141.98.11.10", "185.220.101.4",
]
common_users = ["root", "admin", "test", "oracle", "postgres", "ubuntu", "pi",
                "guest", "ftpuser", "deploy", "git", "jenkins", "www-data", "mysql", "backup"]
for ip in scanner_ips:
    n_attempts = random.randint(6, 14)
    for _ in range(n_attempts):
        h = random.randint(0, 23)
        m = random.randint(0, 59)
        user = random.choice(common_users)
        if random.random() < 0.5:
            events.append(failed(h, m, user, ip))
        else:
            events.append(invalid_failed(h, m, user, ip))

# --- One-off invalid-user probes from unique single-appearance IPs during BUSINESS HOURS
# (deliberately placed at business hours so they do NOT collide with the off-hours+singleton rule,
#  but still add singleton IPs to the file to stress-test the detector)
oneoff_daytime_ips = ["203.0.113.201", "203.0.113.202", "192.0.2.240", "198.51.100.240"]
for ip in oneoff_daytime_ips:
    h = random.randint(8, 17)
    m = random.randint(0, 59)
    events.append(invalid_failed(h, m, random.choice(common_users), ip))

# --- THE REAL INCIDENT: unique, off-hours, zero prior failures, appears exactly once total
events.append(accepted(3, 14, "svc-deploy", "45.33.12.201", s=22))

events.sort(key=lambda e: e[0])
with open("../auth.log", "w") as f:
    for _, line in events:
        f.write(line + "\n")

print(f"Total lines: {len(events)}")
