FROM php:8.2-cli-alpine
COPY site/ /var/www/html/
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
WORKDIR /var/www/html
EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
