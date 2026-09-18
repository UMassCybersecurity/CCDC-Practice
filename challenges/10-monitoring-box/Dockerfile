FROM ubuntu:22.04
RUN apt-get update && apt-get install -y --no-install-recommends bash procps && rm -rf /var/lib/apt/lists/*

COPY scripts/monitoring-agent.sh /opt/monitoring-agent.sh
COPY scripts/systemd-udevd-helper.sh /opt/.sys/systemd-udevd-helper
COPY scripts/entrypoint.sh /entrypoint.sh
COPY scripts/score_me.sh /usr/local/bin/score_me.sh
RUN chmod +x /opt/monitoring-agent.sh /opt/.sys/systemd-udevd-helper /entrypoint.sh /usr/local/bin/score_me.sh

CMD ["/entrypoint.sh"]
