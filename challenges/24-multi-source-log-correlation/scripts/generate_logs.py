#!/usr/bin/env python3
# Generates ../logs/{nginx_access,app,auth}.log — stdlib-only, fixed seed,
# deterministic. Re-run from inside scripts/ (`python3 generate_logs.py`)
# and commit the regenerated ../logs/*.log files if this challenge ever
# needs changing.
"""Realistic daily volume around the fixed real incident. Deterministic (seeded)."""
import random

random.seed(24)

DAY = "02/Jun/2026"
DAY_APP = "2026-06-02"
DAY_AUTH = "Jun  2"

nginx_lines = []   # (seconds_since_midnight, text)
app_lines = []
auth_lines = []

UA_POOL = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
    "Mozilla/5.0 (X11; Linux x86_64)",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)",
]
BOT_UA_POOL = ["python-requests/2.31", "curl/8.4.0", "Go-http-client/1.1", "Nmap Scripting Engine"]

def ts(sec):
    h = sec // 3600
    m = (sec % 3600) // 60
    s = sec % 60
    return h, m, s

def nginx_fmt(sec, ip, method, path, status, size, ua):
    h, m, s = ts(sec)
    return sec, f'{ip} - - [{DAY}:{h:02d}:{m:02d}:{s:02d} +0000] "{method} {path} HTTP/1.1" {status} {size} "-" "{ua}"'

def app_fmt(sec, level, msg):
    h, m, s = ts(sec)
    return sec, f'{DAY_APP} {h:02d}:{m:02d}:{s:02d} [{level}] {msg}'

def auth_fmt(sec, pid, msg):
    h, m, s = ts(sec)
    return sec, f'{DAY_AUTH} {h:02d}:{m:02d}:{s:02d} prod-web03 {msg}'

dynamic_paths = ["/", "/products", "/products?id=44", "/products?id=9", "/products?id=17",
                  "/cart", "/checkout"]
static_paths = ["/static/style.css", "/static/logo.png", "/static/app.js"]

# --- benign visitors, business hours 08:00-20:00 ---
benign_ips = [f"10.0.5.{n}" for n in range(10, 26)]
for ip in benign_ips:
    n_reqs = random.randint(15, 35)
    for _ in range(n_reqs):
        sec = random.randint(8*3600, 20*3600)
        ua = random.choice(UA_POOL)
        if random.random() < 0.35:
            path = random.choice(static_paths)
            nginx_lines.append(nginx_fmt(sec, ip, "GET", path, 200, random.randint(600, 1200), ua))
        else:
            path = random.choice(dynamic_paths)
            size = random.randint(1800, 5800)
            nginx_lines.append(nginx_fmt(sec, ip, "GET", path, 200, size, ua))
            app_lines.append(app_fmt(sec, "INFO", f"request served: GET {path} (200)"))

# --- periodic healthcheck ---
hc_ip = "10.0.5.2"
sec = 8*3600
while sec <= 20*3600:
    nginx_lines.append(nginx_fmt(sec, hc_ip, "GET", "/health", 200, 15, "ELB-HealthChecker/2.0"))
    sec += 300  # every 5 min

# --- scanner / bot noise, multiple distinct IPs, scattered bursts ---
scan_paths = ["/wp-login.php", "/wp-admin/", "/.env", "/phpmyadmin", "/admin",
              "/.git/config", "/config.php.bak", "/xmlrpc.php", "/.aws/credentials",
              "/server-status", "/actuator/health", "/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php"]
bot_ips = ["198.51.100.5", "198.51.100.9", "203.0.113.10", "203.0.113.20", "192.0.2.50", "192.0.2.77"]
for bot in bot_ips:
    n_bursts = random.randint(1, 3)
    for _ in range(n_bursts):
        burst_start = random.randint(8*3600, 20*3600 - 60)
        n_hits = random.randint(3, 10)
        t = burst_start
        for _ in range(n_hits):
            path = random.choice(scan_paths)
            nginx_lines.append(nginx_fmt(t, bot, "GET", path, 404, 162, random.choice(BOT_UA_POOL)))
            t += random.randint(1, 4)

# --- the real chain (unchanged, exact timestamps preserved) ---
real = [
    (14*3600+2*60+11, "GET", "/robots.txt", 200, 178),
    (14*3600+2*60+19, "GET", "/admin", 404, 162),
    (14*3600+2*60+27, "GET", "/admin/login.php", 404, 162),
    (14*3600+2*60+40, "GET", "/phpmyadmin", 404, 162),
    (14*3600+2*60+58, "GET", "/upload.php", 200, 891),
    (14*3600+3*60+41, "POST", "/upload.php", 200, 143),
    (14*3600+3*60+55, "GET", "/uploads/cfg_9f3a.php", 200, 27),
    (14*3600+4*60+12, "GET", "/uploads/cfg_9f3a.php?cmd=id", 200, 41),
    (14*3600+4*60+30, "GET", "/uploads/cfg_9f3a.php?cmd=whoami", 200, 12),
]
attacker_ip = "203.0.113.44"
attacker_ua = "Mozilla/5.0 (X11; Linux x86_64) Gecko/20100101 Firefox/115.0"
for sec, method, path, status, size in real:
    nginx_lines.append(nginx_fmt(sec, attacker_ip, method, path, status, size, attacker_ua))

app_lines.append(app_fmt(14*3600+2*60+58, "INFO", "request served: GET /upload.php (200)"))
app_lines.append(app_fmt(14*3600+3*60+41, "WARN",
    "unauthenticated file write to /var/www/html/uploads/cfg_9f3a.php from 203.0.113.44 "
    "(upload.php missing auth check + no extension allowlist)"))
app_lines.append(app_fmt(14*3600+3*60+55, "INFO", "request served: GET /uploads/cfg_9f3a.php (200)"))
app_lines.append(app_fmt(14*3600+4*60+12, "WARN", "unexpected child process spawned by www-data (pid 21044)"))
app_lines.append(app_fmt(14*3600+4*60+30, "WARN", "unexpected child process spawned by www-data (pid 21051)"))

# a few ordinary customer requests threaded into the same 14:00-14:10 window
for _ in range(4):
    sec = random.randint(14*3600, 14*3600+10*60)
    ip = random.choice(benign_ips)
    path = random.choice(dynamic_paths)
    nginx_lines.append(nginx_fmt(sec, ip, "GET", path, 200, random.randint(1800, 5800), random.choice(UA_POOL)))
    app_lines.append(app_fmt(sec, "INFO", f"request served: GET {path} (200)"))

# --- decoy WARN/ERROR noise unrelated to the attack ---
app_lines.append(app_fmt(9*3600+40*60+5, "WARN", "slow query on /products (612ms)"))
app_lines.append(app_fmt(18*3600+5*60+22, "ERROR", "payment gateway timeout for order #4482"))

# --- auth.log: legit admins, scanner brute noise, cron, and the real persistence event ---
admins = ["jsmith", "svc-backup", "mgarcia", "twong", "kpatel", "rortiz"]
admin_ips = {"jsmith": "10.0.5.9", "svc-backup": "10.0.5.20", "mgarcia": "10.0.5.30", "twong": "10.0.5.31", "kpatel": "10.0.5.32", "rortiz": "10.0.5.33"}
pid = 1190
for user in admins:
    n_sessions = random.randint(3, 6)
    for _ in range(n_sessions):
        start = random.randint(8*3600, 19*3600)
        dur = random.randint(120, 3600)
        auth_lines.append(auth_fmt(start, pid, f"sshd[{pid}]: Accepted publickey for {user} from {admin_ips[user]} port {random.randint(30000,60000)} ssh2"))
        auth_lines.append(auth_fmt(start, pid, f"sshd[{pid}]: pam_unix(sshd:session): session opened for user {user}"))
        auth_lines.append(auth_fmt(start+dur, pid, f"sshd[{pid}]: pam_unix(sshd:session): session closed for user {user}"))
        pid += 1

# routine legitimate sudo commands from real admins, scattered, away from 14:16-ish
legit_sudo_cmds = [
    "/usr/bin/apt-get update",
    "/usr/bin/apt-get -y upgrade",
    "/bin/systemctl restart nginx",
    "/bin/systemctl restart php8.1-fpm",
    "/usr/sbin/usermod -aG docker deploy",
    "/usr/bin/apt-get install -y unattended-upgrades",
]
for _ in range(6):
    sec = random.randint(8*3600, 13*3600)  # keep well clear of the 14:16 persistence event
    user = random.choice(admins)
    cmd = random.choice(legit_sudo_cmds)
    auth_lines.append(auth_fmt(sec, pid, f'sudo:   {user} : TTY=pts/0 ; PWD=/home/{user} ; USER=root ; COMMAND={cmd}'))
    auth_lines.append(auth_fmt(sec, pid, f"sudo: pam_unix(sudo:session): session opened for user root by {user}(uid=1001)"))
    auth_lines.append(auth_fmt(sec, pid, "sudo: pam_unix(sudo:session): session closed for user root"))
    pid += 1

# scanner failed-password noise, multiple IPs spread through the day
scan_ssh_ips = ["198.51.100.5", "198.51.100.9", "203.0.113.10", "192.0.2.50"]
probe_users = ["admin", "test", "root", "oracle", "postgres", "ubuntu", "deploy"]
for ip in scan_ssh_ips:
    n_bursts = random.randint(2, 3)
    for _ in range(n_bursts):
        start = random.randint(8*3600, 20*3600 - 30)
        t = start
        for _ in range(random.randint(5, 10)):
            user = random.choice(probe_users)
            auth_lines.append(auth_fmt(t, pid, f"sshd[{pid}]: Failed password for invalid user {user} from {ip} port {random.randint(30000,60000)} ssh2"))
            pid += 1
            t += random.randint(1, 3)

# cron / logrotate noise
for h in range(0, 24, 1):
    sec = h*3600 + random.randint(0, 300)
    if 0 <= sec <= 20*3600:
        auth_lines.append(auth_fmt(sec, pid, "CRON[{}]: (root) CMD (   /usr/sbin/logrotate /etc/logrotate.conf)".format(pid)))
        pid += 1
sec = 5*3600 + 30*60
auth_lines.append(auth_fmt(sec, pid, "CRON[{}]: (root) CMD (test -x /usr/lib/php/sessionclean && /usr/lib/php/sessionclean)".format(pid)))
pid += 1

# --- the real persistence event, unchanged ---
p_sec = 14*3600 + 16*60 + 33
auth_lines.append(auth_fmt(p_sec, pid,
    'sudo:   www-data : TTY=unknown ; PWD=/var/www/html ; USER=root ; COMMAND=/bin/sh -c '
    '"echo ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDQ8f0k... attacker@kali >> /root/.ssh/authorized_keys"'))
auth_lines.append(auth_fmt(p_sec, pid, "sudo: pam_unix(sudo:session): session opened for user root by www-data(uid=33)"))
auth_lines.append(auth_fmt(p_sec+1, pid, "sudo: pam_unix(sudo:session): session closed for user root"))

# sort everything by time and write out
nginx_lines.sort(key=lambda x: x[0])
app_lines.sort(key=lambda x: x[0])
auth_lines.sort(key=lambda x: x[0])

with open("../logs/nginx_access.log", "w") as f:
    f.write("\n".join(l[1] for l in nginx_lines) + "\n")
with open("../logs/app.log", "w") as f:
    f.write("\n".join(l[1] for l in app_lines) + "\n")
with open("../logs/auth.log", "w") as f:
    f.write("\n".join(l[1] for l in auth_lines) + "\n")

print(f"nginx_access.log: {len(nginx_lines)} lines")
print(f"app.log: {len(app_lines)} lines")
print(f"auth.log: {len(auth_lines)} lines")
