FROM php:8.2-apache

ENV ROADMAPVERSION=1.36

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    libzip-dev \
    zip \
    npm \
    postgresql \
    libxml2-dev
    
RUN apt-get install -y wget
RUN apt-get install libpq-dev

# Enable mod_rewrite
RUN a2enmod rewrite

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql zip pdo_pgsql

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Make app directory
RUN mkdir app

# Install laravel requirements + package
RUN wget https://github.com/ploi-deploy/roadmap/archive/refs/tags/${ROADMAPVERSION}.zip \
    && unzip ${ROADMAPVERSION}.zip \
    && mv roadmap-${ROADMAPVERSION}/* /var/www/html \
    && chmod +x /var/www/html

# Copy the application code
COPY . /var/www/html

# Set the working directory
WORKDIR /var/www/html

# Set permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

RUN npm cache clean -f
RUN npm install -g n
RUN docker-php-ext-install \
                   xml


COPY init.sh /opt/docker/provision/entrypoint.d/99-init.sh

ENV APP_ENV production
WORKDIR /app

ENV WEB_DOCUMENT_ROOT /app/public

VOLUME /var/www/html
VOLUME /app
VOLUME /vendor

EXPOSE 9000
