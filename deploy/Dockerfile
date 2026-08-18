# syntax=docker/dockerfile:1.7

FROM node:24-alpine AS admin-builder

RUN corepack enable && corepack prepare pnpm@10.33.0 --activate

WORKDIR /build/saiadmin-artd

COPY saiadmin-artd/package.json saiadmin-artd/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY saiadmin-artd/ ./
RUN pnpm exec vite build \
    && pnpm exec vue-tsc --noEmit


FROM alpine:3.22 AS php-runtime-base

ENV APP_ENV=production \
    APP_DEBUG=false

RUN apk add --no-cache \
        ca-certificates \
        su-exec \
        php83 \
        php83-bcmath \
        php83-curl \
        php83-dom \
        php83-fileinfo \
        php83-gd \
        php83-iconv \
        php83-intl \
        php83-mbstring \
        php83-mysqli \
        php83-opcache \
        php83-openssl \
        php83-pcntl \
        php83-pdo \
        php83-pdo_mysql \
        php83-pecl-opentelemetry \
        php83-pecl-redis \
        php83-phar \
        php83-posix \
        php83-session \
        php83-simplexml \
        php83-sockets \
        php83-tokenizer \
        php83-xml \
        php83-xmlreader \
        php83-xmlwriter \
        php83-zip \
    && addgroup -S app \
    && adduser -S -D -G app app


FROM php-runtime-base AS php-dependencies

COPY --from=composer:2.8 /usr/bin/composer /usr/local/bin/composer

WORKDIR /build

COPY packages/ ./packages/
COPY server/ ./server/

RUN composer install \
    --working-dir=server \
    --no-dev \
    --prefer-dist \
    --optimize-autoloader \
    --no-interaction \
    --no-progress \
    && rm -f server/.env


FROM php-runtime-base AS runtime

WORKDIR /app/server

COPY --from=php-dependencies /build/server/ /app/server/
COPY --from=admin-builder /build/saiadmin-artd/dist/ /app/server/public/admin/
COPY Database/ /app/Database/
COPY deploy/docker/php.ini /etc/php83/conf.d/99_helpsupport.ini
COPY deploy/docker/entrypoint.sh /usr/local/bin/helpsupport-entrypoint
COPY deploy/docker/healthcheck.php /usr/local/bin/helpsupport-healthcheck.php

RUN rm -f /app/server/.env \
    && mkdir -p /app/server/runtime/logs /app/server/public/storage \
    && chown -R app:app /app \
    && chmod 0755 /usr/local/bin/helpsupport-entrypoint

EXPOSE 8787 8791

ENTRYPOINT ["/usr/local/bin/helpsupport-entrypoint"]
CMD ["serve"]
