FROM composer AS application_builder
ENV ROADMAPVERSION=1.42

RUN wget https://github.com/ploi-deploy/roadmap/archive/refs/tags/1.42.zip \
    && unzip 1.42.zip \
    && mv roadmap-1.42/* /app \
    && chmod +x /app
    
WORKDIR /app

RUN mkdir -p storage/framework/cache \
    && mkdir -p storage/framework/views \
    && mkdir -p storage/framework/sessions \
    && composer install --optimize-autoloader --no-dev
    
FROM node:17.4-alpine As asset_builder

ENV APP_ENV production

RUN wget https://github.com/ploi-deploy/roadmap/archive/refs/tags/1.42.zip \
    && unzip 1.42.zip \
    && mv roadmap-1.42/* /app \
    && chmod +x /app


    
WORKDIR /app

RUN npm install \
    && npm run build


FROM php:fpm-alpine
WORKDIR /var/www/html

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install mysqli \
    && docker-php-ext-install opcache \
    && docker-php-ext-install intl \
    && docker-php-ext-install sockets \
    && apk add --no-cache \
    mariadb-client \
    sqlite \
    nginx

COPY . ./

COPY --from=application_builder /app/vendor ./vendor
COPY --from=application_builder /app/bootstrap/cache ./bootstrap/cache

COPY --from=asset_builder /app/public/build ./public/build

RUN mkdir ./database/sqlite \
    && chown -R www-data: /var/www/html \
    && rm -rf ./docker

COPY ./docker/config/ploiroadmap-php.ini /usr/local/etc/php/conf.d/ploiroadmap-php.ini
COPY ./docker/config/nginx.conf /etc/nginx/nginx.conf
COPY ./docker/config/site-nginx.conf /etc/nginx/http.d/default.conf

CMD ["chmod +x ./docker-entrypoint.sh"]

EXPOSE 80

VOLUME /app
VOLUME /vendor

RUN chown -R application:application .

CMD ["./init.sh"]
