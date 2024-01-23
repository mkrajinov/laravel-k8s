FROM node:20-alpine as node

WORKDIR /app

COPY . .

RUN npm install

RUN npm run build


FROM laravelsail/php82-composer:latest as composer

RUN groupadd --force -g 1000 composer
RUN useradd -ms /bin/bash --no-user-group -g 1000 -u 1000 composer
USER composer

WORKDIR /app

COPY ./composer.json ./composer.lock ./

RUN composer install --optimize-autoloader --no-scripts --no-interaction --ignore-platform-reqs

FROM php:8.2-fpm-alpine

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN apk add --virtual build-dependencies --no-cache ${PHPIZE_DEPS}
RUN set -ex && apk --no-cache add postgresql-dev
RUN docker-php-ext-install pdo pdo_pgsql
RUN pecl install redis && docker-php-ext-enable redis

WORKDIR /srv/app

USER  www-data

COPY --chown=www-data ./ ./
COPY --chown=www-data --from=composer ./app/vendor ./vendor
COPY --chown=www-data --from=node /app/public ./public
