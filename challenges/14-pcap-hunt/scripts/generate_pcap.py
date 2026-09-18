#!/usr/bin/env python3
"""Deterministic generator for capture.pcap — run once, commit the output.
Requires scapy (not a runtime dependency of the challenge image).

The two real signals (the plaintext login and the C2 beacon) are built
first, with fixed timestamps, and never touched by the noise below —
only noise-packet jitter uses the seeded RNG, so the answer stays
byte-for-byte stable across regenerations."""
import random
from scapy.all import IP, TCP, UDP, Raw, wrpcap
from scapy.layers.dns import DNS, DNSQR, DNSRR

T0 = 1710400000.0  # fixed epoch so the real signal is byte-for-byte reproducible
rng = random.Random(1337)  # noise-only jitter

pkts = []

# --- Plaintext HTTP login (creds in the clear) — THE ANSWER, unchanged ---
client, server = "10.0.5.20", "10.0.5.30"
csport, dport = 51500, 80

syn = IP(src=client, dst=server) / TCP(sport=csport, dport=dport, flags="S", seq=1000)
syn.time = T0
synack = IP(src=server, dst=client) / TCP(sport=dport, dport=csport, flags="SA", seq=5000, ack=1001)
synack.time = T0 + 0.01
ack = IP(src=client, dst=server) / TCP(sport=csport, dport=dport, flags="A", seq=1001, ack=5001)
ack.time = T0 + 0.02

body = "username=jdoe&password=Fall2025!"
http_req = (
    "POST /login HTTP/1.1\r\n"
    "Host: intranet.corp\r\n"
    "Content-Type: application/x-www-form-urlencoded\r\n"
    f"Content-Length: {len(body)}\r\n\r\n{body}"
)
push = IP(src=client, dst=server) / TCP(sport=csport, dport=dport, flags="PA", seq=1001, ack=5001) / Raw(load=http_req)
push.time = T0 + 0.03

resp_body = "OK"
http_resp = f"HTTP/1.1 200 OK\r\nContent-Length: {len(resp_body)}\r\n\r\n{resp_body}"
respdata = IP(src=server, dst=client) / TCP(sport=dport, dport=csport, flags="PA", seq=5001, ack=1001 + len(http_req)) / Raw(load=http_resp)
respdata.time = T0 + 0.05

pkts += [syn, synack, ack, push, respdata]

# --- C2 beacon traffic — THE ANSWER, unchanged ---
c2_ip, c2_port = "203.0.113.50", 4444
for i in range(6):
    beacon = IP(src=client, dst=c2_ip) / UDP(sport=54000 + i, dport=c2_port) / Raw(
        load=f"User-Agent: BeaconClient/1.0\r\ncheckin=alive;id=victim01;seq={i}"
    )
    beacon.time = T0 + 10 + i * 30
    pkts.append(beacon)

WINDOW = 590  # noise spans the same ~10 minute window as the real traffic
NOISE_CLIENTS = ["10.0.5.21", "10.0.5.22", "10.0.5.23", "10.0.5.24", "10.0.5.25"]

# --- Noise: benign HTTP GET flows to a few different internal servers ---
# so `-Y http` no longer isolates a single request.
NOISE_SERVERS = [
    ("10.0.5.31", "intranet-wiki.corp", "/"),
    ("10.0.5.32", "files.corp", "/reports/q3.pdf"),
    ("10.0.5.30", "intranet.corp", "/dashboard"),
]
sport_ctr = 40000
for _ in range(25):
    c = rng.choice(NOISE_CLIENTS)
    s, host, path = rng.choice(NOISE_SERVERS)
    sport = sport_ctr
    sport_ctr += 1
    t = T0 + rng.uniform(0, WINDOW)
    seq_c, seq_s = rng.randint(1000, 90000), rng.randint(1000, 90000)

    n_syn = IP(src=c, dst=s) / TCP(sport=sport, dport=80, flags="S", seq=seq_c)
    n_syn.time = t
    n_sa = IP(src=s, dst=c) / TCP(sport=80, dport=sport, flags="SA", seq=seq_s, ack=seq_c + 1)
    n_sa.time = t + 0.01
    n_ack = IP(src=c, dst=s) / TCP(sport=sport, dport=80, flags="A", seq=seq_c + 1, ack=seq_s + 1)
    n_ack.time = t + 0.02

    req = f"GET {path} HTTP/1.1\r\nHost: {host}\r\n\r\n"
    n_push = IP(src=c, dst=s) / TCP(sport=sport, dport=80, flags="PA", seq=seq_c + 1, ack=seq_s + 1) / Raw(load=req)
    n_push.time = t + 0.03

    resp = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK"
    n_resp = IP(src=s, dst=c) / TCP(sport=80, dport=sport, flags="PA", seq=seq_s + 1, ack=seq_c + 1 + len(req)) / Raw(load=resp)
    n_resp.time = t + 0.05
    n_fin = IP(src=c, dst=s) / TCP(sport=sport, dport=80, flags="FA", seq=seq_c + 1 + len(req), ack=seq_s + 1 + len(resp))
    n_fin.time = t + 0.06

    pkts += [n_syn, n_sa, n_ack, n_push, n_resp, n_fin]

# --- Noise: DNS query/response pairs, mixed in with the other UDP traffic
# so `-Y udp` no longer isolates the beacon by itself. ---
DNS_DOMAINS = ["intranet.corp", "files.corp", "updates.microsoft.com", "api.slack.com", "login.microsoftonline.com", "pool.ntp.org"]
resolver = "10.0.5.1"
dns_sport = 33000
for _ in range(60):
    c = rng.choice(NOISE_CLIENTS + [client])
    domain = rng.choice(DNS_DOMAINS)
    t = T0 + rng.uniform(0, WINDOW)
    sport = dns_sport
    dns_sport += 1

    q = IP(src=c, dst=resolver) / UDP(sport=sport, dport=53) / DNS(rd=1, qd=DNSQR(qname=domain))
    q.time = t
    r = IP(src=resolver, dst=c) / UDP(sport=53, dport=sport) / DNS(
        qr=1, rd=1, qd=DNSQR(qname=domain),
        an=DNSRR(rrname=domain, rdata=f"10.0.5.{rng.randint(40, 60)}"),
    )
    r.time = t + rng.uniform(0.01, 0.05)
    pkts += [q, r]

# --- Noise: one-way syslog-style UDP chatter to a log collector — more UDP
# traffic that isn't the beacon and isn't DNS. ---
logsvr = "10.0.5.40"
syslog_msgs = [
    "cron[1021]: (root) CMD (run-parts /etc/cron.hourly)",
    "sshd[2044]: Accepted publickey for jsmith from 10.0.5.21 port 51221",
    "systemd[1]: Started Session 42 of user jsmith.",
    "kernel: [UFW BLOCK] IN=eth0 OUT= SRC=198.51.100.9",
]
syslog_sport = 45000
for _ in range(80):
    c = rng.choice(NOISE_CLIENTS)
    t = T0 + rng.uniform(0, WINDOW)
    msg = rng.choice(syslog_msgs)
    pkt = IP(src=c, dst=logsvr) / UDP(sport=syslog_sport, dport=514) / Raw(load=f"<134>{msg}")
    pkt.time = t
    syslog_sport += 1
    pkts.append(pkt)

pkts.sort(key=lambda p: p.time)

wrpcap("capture.pcap", pkts)
print(f"wrote capture.pcap with {len(pkts)} packets")
