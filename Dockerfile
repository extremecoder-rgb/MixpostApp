FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    zip \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    sqlite3 \
    libsqlite3-dev \
    pkg-config \
    curl

# Install PHP extensions
RUN docker-php-ext-configure pdo_sqlite --with-pdo-sqlite=/usr \
    && docker-php-ext-install pdo pdo_mysql pdo_sqlite mbstring exif pcntl bcmath gd zip

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy project files
COPY . .

# Create required Laravel folders
RUN mkdir -p bootstrap/cache \
    storage \
    storage/framework/sessions \
    storage/framework/views \
    storage/framework/cache

# Copy the default .env
RUN cp .env.example .env

# Set correct environment values inside container
RUN echo "APP_ENV=production" >> .env \
 && echo "APP_DEBUG=false" >> .env \
 && echo "DB_CONNECTION=sqlite" >> .env \
 && echo "DB_DATABASE=/var/www/html/storage/database.sqlite" >> .env \
 && echo "SESSION_DRIVER=file" >> .env \
 && echo "QUEUE_CONNECTION=database" >> .env \
 && echo "FILESYSTEM_DISK=local" >> .env \
 && echo "CACHE_DRIVER=file" >> .env

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Set permissions
RUN chmod -R 777 storage bootstrap/cache

# Clear cached config BEFORE generating key
RUN php artisan config:clear

# Generate APP_KEY
RUN php artisan key:generate --force

# Create SQLite DB
RUN touch storage/database.sqlite \
 && chmod -R 777 storage/database.sqlite storage

# Run migrations
RUN php artisan migrate --force || true

# Link storage
RUN php artisan storage:link || true

# Expose Render port
EXPOSE 8080

# Start Laravel server
CMD php artisan serve --host=0.0.0.0 --port=8080
