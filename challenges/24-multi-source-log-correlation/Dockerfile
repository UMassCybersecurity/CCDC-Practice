FROM alpine:3.20

RUN apk add --no-cache bash grep gawk coreutils

COPY logs/ /var/log/
COPY scripts/score_me.sh /scripts/score_me.sh
RUN chmod +x /scripts/score_me.sh

CMD ["tail", "-f", "/dev/null"]
