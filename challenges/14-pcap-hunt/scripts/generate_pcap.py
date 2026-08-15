#!/usr/bin/env python3
"""Deterministic generator for capture.pcap — run once, commit the output.
Requires scapy (not a runtime dependency of the challenge image)."""
from scapy.all import IP, TCP, UDP, Raw, wrpcap

T0 = 1710400000.0  # fixed epoch so output is byte-for-byte reproducible

pkts = []

# --- Plaintext HTTP login (creds in the clear) ---
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

# --- C2 beacon traffic ---
c2_ip, c2_port = "203.0.113.50", 4444
for i in range(6):
    beacon = IP(src=client, dst=c2_ip) / UDP(sport=54000 + i, dport=c2_port) / Raw(
        load=f"User-Agent: BeaconClient/1.0\r\ncheckin=alive;id=victim01;seq={i}"
    )
    beacon.time = T0 + 10 + i * 30
    pkts.append(beacon)

wrpcap("capture.pcap", pkts)
print(f"wrote capture.pcap with {len(pkts)} packets")
