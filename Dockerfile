# Stage 1: build frontend assets
FROM node:22-alpine AS node_builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build
RUN test -d /app/public/build/assets || (echo "ERROR: Vite produced no assets" && exit 1)

# Stage 2: PHP image (PHP 8.4 — match Herd / vercel-php@0.8.0)
FROM serversideup/php:8.4-fpm-nginx
ENV PHP_OPCACHE_ENABLE=1

USER root
COPY docker/nginx-vite-assets.conf /etc/nginx/site-opts.d/10-vite-assets.conf

USER www-data
COPY --chown=www-data:www-data composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist
COPY --chown=www-data:www-data . .
COPY --chown=www-data:www-data --from=node_builder /app/public/build ./public/build
RUN test -d public/build/assets || (echo "ERROR: assets missing from final image" && exit 1)
RUN composer dump-autoload --optimize
RUN chmod -R 775 storage bootstrap/cache
