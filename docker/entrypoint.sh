#!/bin/sh
set -e

echo "Starting PHP-FPM..."
php-fpm -D

echo "Waiting for PHP-FPM to be ready..."
for i in $(seq 1 10); do
    if kill -0 "$(cat /var/run/php/php-fpm.pid 2>/dev/null)" 2>/dev/null; then
        echo "PHP-FPM is ready."
        break
    fi
    echo "Waiting... ($i/10)"
    sleep 1
done

echo "Starting Nginx..."
exec nginx -g 'daemon off;'
