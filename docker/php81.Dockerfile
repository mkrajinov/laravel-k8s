FROM node:16.13.1-alpine as node

WORKDIR /app

COPY . .

RUN npm install

RUN npm run prod


FROM laravelsail/php81-composer:latest as composer

RUN groupadd --force -g 1000 composer
RUN useradd -ms /bin/bash --no-user-group -g 1000 -u 1000 composer
USER composer

WORKDIR /app

COPY ./composer.json .

COPY . .

RUN composer install --optimize-autoloader

FROM php:8.1-fpm-alpine

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN apk add --virtual build-dependencies --no-cache ${PHPIZE_DEPS}
RUN docker-php-ext-install pdo pdo_mysql
RUN pecl install redis && docker-php-ext-enable redis

WORKDIR /srv/app

USER  www-data

COPY --chown=www-data --from=composer /app/ .
COPY --chown=www-data --from=node /app/public/ ./public/
