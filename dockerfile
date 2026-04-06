FROM php:8.4-fpm

# Build arg: set to "true" when building for tests (includes PHPUnit etc.)
ARG INSTALL_DEV=false

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libpq-dev \
    zip \
    unzip \
    nginx \
    && docker-php-ext-install pdo pdo_pgsql pgsql mbstring exif pcntl bcmath gd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (for Vite/Tailwind asset compilation)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy only dependency manifests first (better layer caching)
COPY composer.json composer.lock ./
COPY package.json package-lock.json* ./

# Install PHP dependencies
RUN if [ "$INSTALL_DEV" = "true" ]; then \
        composer install --optimize-autoloader; \
    else \
        composer install --optimize-autoloader --no-dev; \
    fi

# Install Node dependencies and build frontend assets
RUN npm ci --ignore-scripts
COPY resources/ resources/
COPY vite.config.js ./
RUN npm run build

# Copy the rest of the application
COPY . .

# Set permissions
RUN chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www/storage \
    && chmod -R 755 /var/www/bootstrap/cache

# Copy Nginx config and entrypoint
COPY docker/nginx.conf /etc/nginx/sites-available/default
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose port 80
EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
