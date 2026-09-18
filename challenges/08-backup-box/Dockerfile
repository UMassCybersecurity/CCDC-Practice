FROM ubuntu:22.04

RUN apt-get update && apt-get install -y --no-install-recommends cron && rm -rf /var/lib/apt/lists/*

COPY scripts/setup.sh /setup.sh
RUN chmod +x /setup.sh && /setup.sh && rm /setup.sh

COPY scripts/score_me.sh /usr/local/bin/score_me.sh
RUN chmod +x /usr/local/bin/score_me.sh

CMD ["cron", "-f"]
