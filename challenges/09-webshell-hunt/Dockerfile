FROM php:8.2-cli-alpine
COPY site/ /var/www/html/
WORKDIR /var/www/html
EXPOSE 80
CMD ["php", "-S", "0.0.0.0:80", "-t", "/var/www/html"]
