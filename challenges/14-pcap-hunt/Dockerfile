FROM debian:12-slim

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends tshark && \
    rm -rf /var/lib/apt/lists/*

COPY capture.pcap /root/capture.pcap
COPY scripts/score_me.sh /scripts/score_me.sh
RUN chmod +x /scripts/score_me.sh

CMD ["tail", "-f", "/dev/null"]
