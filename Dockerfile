FROM php:8.2-apache

ENV ROADMAPVERSION=1.36

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    libzip-dev \
    zip \
    npm \
    oniguruma-dev \
    postgresql-dev 
    libxml2-dev \
    wget \
    unzip
    
# Enable mod_rewrite
RUN a2enmod rewrite

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql zip

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Install laravel requirements + package
RUN wget https://github.com/ploi-deploy/roadmap/archive/refs/tags/${ROADMAPVERSION}.zip \
    && unzip ${ROADMAPVERSION}.zip \
    && mv roadmap-${ROADMAPVERSION}/* /app \
    && chmod +x /app

# Copy the application code
COPY . /var/www/html

# Set the working directory
WORKDIR /var/www/html

# Copy Composer binary from the Composer official Docker image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install project dependencies
RUN composer install

# Set permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

RUN npm cache clean -f
RUN npm install -g n
RUN docker-php-ext-install \
        ctype \
        fileinfo \
        mbstring \
        xml

ENV WEB_DOCUMENT_ROOT /app/public

ENV APP_ENV production
WORKDIR /app

COPY init.sh /opt/docker/provision/entrypoint.d/99-init.sh

RUN chown -R application:application .

VOLUME /app
VOLUME /vendor

EXPOSE 9000
