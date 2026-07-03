#!/bin/bash
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/credentials | head -1)
WP_USER_PASSWORD=$(cat /run/secrets/credentials | tail -1)

# wait for MariaDB to accept connections
until mariadb -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASSWORD}" -e "SELECT 1;" &>/dev/null; do
    echo "Waiting for MariaDB to be ready..."
    sleep 2
done
echo "MariaDB is ready."
cd /var/www/html

if [ ! -f "wp-config.php" ]; then
    wp core download --allow-root

    wp config create \
        --dbname="${DB_NAME}" \
        --dbuser="${DB_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="${DB_HOST}" \
        --allow-root

    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root

    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root
fi

exec php-fpm8.2 -F
