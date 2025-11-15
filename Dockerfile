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

# Copy application files
COPY . .

# Create missing folders
RUN mkdir -p bootstrap/cache \
    storage \
    storage/framework/sessions \
    storage/framework/views \
    storage/framework/cache

# Create .env file automatically
RUN cp .env.example .env

# Install dependencies
RUN composer install --no-dev --optimize-autoloader

# Permissions
RUN chmod -R 777 storage bootstrap/cache

# Generate APP_KEY
RUN php artisan key:generate --force

# Create SQLite DB automatically
RUN touch storage/database.sqlite

# Run migrations
RUN php artisan migrate --force || true

# Link storage
RUN php artisan storage:link || true

EXPOSE 8080

CMD php artisan serve --host=0.0.0.0 --port=8080
