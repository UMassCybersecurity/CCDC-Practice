FROM alpine:3.20

RUN apk add --no-cache bash grep gawk

COPY evidence/autoruns.csv evidence/scheduled_tasks.txt evidence/ifeo_registry.txt evidence/security_events.csv /evidence/
COPY scripts/score_me.sh /scripts/score_me.sh
RUN chmod +x /scripts/score_me.sh

CMD ["tail", "-f", "/dev/null"]
