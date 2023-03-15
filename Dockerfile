FROM webdevops/php-nginx:8.1-alpine

ENV ROADMAPVERSION=1.42


# Install Laravel framework system requirements (https://laravel.com/docs/8.x/deployment#optimizing-configuration-loading)
RUN apk add oniguruma-dev postgresql-dev libxml2-dev
RUN apk add npm
RUN npm cache clean -f
RUN npm install -g n
RUN docker-php-ext-install \
        ctype \
        fileinfo \
        mbstring \
        xml

# Copy Composer binary from the Composer official Docker image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

ENV WEB_DOCUMENT_ROOT /app/public

RUN wget https://github.com/ploi-deploy/roadmap/archive/refs/tags/${ROADMAPVERSION}.zip \
    && unzip ${ROADMAPVERSION}.zip \
    && mv roadmap-${ROADMAPVERSION}/* /app \
    && chmod +x /app

ENV APP_ENV production
WORKDIR /app

COPY ./nginx/10-location-root.conf /opt/docker/etc/nginx/vhost.common.d/
COPY ./nginx/app.conf /opt/docker/etc/nginx/vhost.common.d/

COPY init.sh /opt/docker/provision/entrypoint.d/99-init.sh

RUN chown -R application:application .

VOLUME /app
VOLUME /vendor
