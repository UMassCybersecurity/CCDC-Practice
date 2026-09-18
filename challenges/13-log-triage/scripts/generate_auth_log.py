#!/usr/bin/env python3
"""Deterministic generator for auth.log — run once, commit the output.
Stdlib only. Re-run after editing to regenerate byte-for-byte.

Produces a realistic ~24h volume of sshd/cron noise around one real
incident (203.0.113.77 brute-forcing dave, succeeding at
Mar 14 02:11:03) so the answer can't just be eyeballed in a 27-line file.
The incident block's lines/timestamps are verbatim from the original
hand-written log and must not change — score_me.sh grep -qx's them
exactly.
"""
import random

random.seed(1337)

HOST = "prod-web01"
YEAR_BASE = 1710288000  # Mar 13 00:00:00 2024 UTC-ish, arbitrary fixed epoch

pid = 18000


def next_pid():
    global pid
    pid += random.randint(1, 40)
    return pid


def fmt(ts, msg):
    import time
    t = time.gmtime(ts)
    return f"{time.strftime('%b %e', t).replace('  ', ' ')} {time.strftime('%H:%M:%S', t)} {HOST} {msg}"


events = []  # (ts, line)

# --- Scanner noise: 14 external IPs throwing failed logins at common
# usernames all day, none ever succeed. ---
SCANNER_IPS = [
    "198.51.100.23", "192.0.2.55", "45.83.64.12", "89.248.165.43",
    "91.196.152.7", "141.98.10.62", "185.220.101.4", "193.32.162.99",
    "162.243.144.19", "104.152.52.32", "203.0.113.9", "198.51.100.201",
    "192.0.2.211", "45.146.164.88",
]
COMMON_USERS = [
    "admin", "root", "test", "oracle", "postgres", "ubuntu", "pi",
    "deploy", "guest", "www-data", "git", "ftpuser", "jenkins", "mysql",
    "elastic", "backup", "user", "support",
]

for ip in SCANNER_IPS:
    n_attempts = random.randint(10, 45)
    start = YEAR_BASE + random.randint(0, 86400 * 2 - 3600)
    t = start
    for _ in range(n_attempts):
        user = random.choice(COMMON_USERS)
        port = random.randint(30000, 65000)
        if random.random() < 0.15:
            events.append((t, f'sshd[{next_pid()}]: Invalid user {user} from {ip} port {port}'))
        events.append((t, f'sshd[{next_pid()}]: Failed password for invalid user {user} from {ip} port {port} ssh2'
                       if user in ("admin", "test", "oracle", "guest", "pi", "backup", "support")
                       else f'sshd[{next_pid()}]: Failed password for {user} from {ip} port {port} ssh2'))
        if random.random() < 0.3:
            events.append((t + 1, f'sshd[{next_pid()}]: Received disconnect from {ip} port {port}:11: disconnected by user'))
        t += random.randint(15, 400)

# --- Legitimate internal logins: clean, no preceding failures. ---
LEGIT_USERS = [
    ("svc-backup", "10.0.5.12", 1010),
    ("jsmith", "10.0.5.44", 1005),
    ("alice", "10.0.5.18", 1021),
    ("bmartin", "10.0.5.51", 1022),
    ("carol", "10.0.5.9", 1023),
    ("jenkins-ci", "10.0.5.60", 1030),
]
for user, ip, uid in LEGIT_USERS:
    n_sessions = random.randint(1, 4)
    for _ in range(n_sessions):
        t = YEAR_BASE + random.randint(0, 86400 * 2 - 60)
        port = random.randint(50000, 65000)
        method = random.choice(["password", "publickey"])
        if method == "publickey":
            events.append((t, f'sshd[{next_pid()}]: Accepted publickey for {user} from {ip} port {port} ssh2: RSA SHA256:{"".join(random.choices("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", k=43))}'))
        else:
            events.append((t, f'sshd[{next_pid()}]: Accepted password for {user} from {ip} port {port} ssh2'))
        events.append((t, f'sshd[{next_pid()}]: pam_unix(sshd:session): session opened for user {user}(uid={uid}) by (uid=0)'))
        if random.random() < 0.6:
            dur = random.randint(30, 1800)
            events.append((t + dur, f'sshd[{next_pid()}]: pam_unix(sshd:session): session closed for user {user}'))

# --- Cron/PAM housekeeping noise every ~10-20 minutes, all day. ---
CRON_JOBS = [
    "/usr/lib/php/sessionclean",
    "/usr/bin/certbot -q renew",
    "/etc/cron.daily/logrotate",
    "/etc/cron.daily/apt-compat",
    "/usr/local/bin/backup-verify.sh",
    "/usr/sbin/anacron -s",
]
t = YEAR_BASE
while t < YEAR_BASE + 86400 * 2:
    job = random.choice(CRON_JOBS)
    events.append((t, f'CRON[{next_pid()}]: (root) CMD ({job})'))
    if random.random() < 0.3:
        events.append((t, 'CRON[{}]: pam_unix(cron:session): session opened for user root(uid=0) by (uid=0)'.format(next_pid())))
    t += random.randint(600, 1400)

# --- The real incident: verbatim, unchanged timestamps/PIDs/wording. ---
INCIDENT = """\
Mar 14 01:58:11 prod-web01 sshd[20811]: Failed password for invalid user admin from 198.51.100.23 port 44210 ssh2
Mar 14 02:10:01 prod-web01 sshd[21001]: Failed password for dave from 203.0.113.77 port 51230 ssh2
Mar 14 02:10:09 prod-web01 sshd[21003]: Failed password for dave from 203.0.113.77 port 51231 ssh2
Mar 14 02:10:17 prod-web01 sshd[21005]: Failed password for dave from 203.0.113.77 port 51232 ssh2
Mar 14 02:10:24 prod-web01 sshd[21007]: Failed password for dave from 203.0.113.77 port 51233 ssh2
Mar 14 02:10:32 prod-web01 sshd[21009]: Failed password for dave from 203.0.113.77 port 51234 ssh2
Mar 14 02:10:39 prod-web01 sshd[21011]: Failed password for dave from 203.0.113.77 port 51235 ssh2
Mar 14 02:10:47 prod-web01 sshd[21013]: Failed password for dave from 203.0.113.77 port 51236 ssh2
Mar 14 02:10:55 prod-web01 sshd[21015]: Failed password for dave from 203.0.113.77 port 51237 ssh2
Mar 14 02:11:03 prod-web01 sshd[21017]: Accepted password for dave from 203.0.113.77 port 51238 ssh2
Mar 14 02:11:03 prod-web01 sshd[21017]: pam_unix(sshd:session): session opened for user dave(uid=1002) by (uid=0)
Mar 14 02:11:40 prod-web01 sshd[21017]: Received disconnect from 203.0.113.77 port 51238:11: disconnected by user
Mar 14 02:13:12 prod-web01 sshd[21080]: Accepted publickey for dave from 203.0.113.77 port 51300 ssh2: RSA SHA256:9fJ3kQwZpL0y5vC2xN8mA1tR6bE4dF7hK3sJ0oP2qWc
Mar 14 02:13:12 prod-web01 sshd[21080]: pam_unix(sshd:session): session opened for user dave(uid=1002) by (uid=0)
Mar 14 02:14:02 prod-web01 crontab[21099]: (dave) BEGIN EDIT (crontab.1710396842)
Mar 14 02:14:05 prod-web01 crontab[21099]: (dave) REPLACE (crontab.1710396842)
Mar 14 02:14:05 prod-web01 crontab[21099]: (dave) END EDIT (crontab.1710396842)
Mar 14 02:14:47 prod-web01 sshd[21080]: Received disconnect from 203.0.113.77 port 51300:11: disconnected by user
"""

# --- Assemble, sort noise by time, keep incident block as literal lines
# spliced in verbatim (not re-sorted individually — their relative order
# and exact timestamps/PIDs must not change). ---
events.sort(key=lambda e: e[0])
noise_lines = [fmt(ts, msg) for ts, msg in events]

# Splice: everything is Mar 13-14; put the incident's fixed lines in
# their correct chronological slot among the generated noise by
# comparing formatted timestamp strings (safe since format is fixed
# width "Mon D HH:MM:SS" / "Mon DD HH:MM:SS").
import time


def sort_key(line):
    # "Mon D(D) HH:MM:SS host ..." -> parse into a comparable tuple.
    # All events are within a 2-day window so date+time string compares
    # correctly once month/day/time are normalized to fixed width.
    parts = line.split()
    mon, day, clock = parts[0], parts[1], parts[2]
    return (mon, int(day), clock)


all_lines = noise_lines + INCIDENT.strip("\n").split("\n")
all_lines.sort(key=sort_key)

with open("auth.log", "w") as f:
    f.write("\n".join(all_lines) + "\n")

print(f"wrote {len(all_lines)} lines")
