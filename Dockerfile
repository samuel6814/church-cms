# Render: Docker web service (NOT Render native PHP).
# React SPA is built and hosted on Vercel — this image is API-only.
FROM serversideup/php:8.4-fpm-nginx

ENV PHP_OPCACHE_ENABLE=1
ENV NGINX_WEBROOT=/var/www/html/public

USER www-data
WORKDIR /var/www/html

COPY --chown=www-data:www-data composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

COPY --chown=www-data:www-data . .

RUN composer dump-autoload --optimize
RUN chmod -R 775 storage bootstrap/cache
