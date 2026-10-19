#!/bin/bash

set -e

DB_PORT=3306
export HTTP_HOST="$DOMAIN_NAME"
cd /var/www/html


if [ ! -f wp-load.php ]; then
    wp core download --allow-root
fi

until php -r '
mysqli_report(MYSQLI_REPORT_OFF);
$db = @new mysqli(getenv("DB_HOST"), getenv("MYSQL_USER"), getenv("MYSQL_PASSWORD"), getenv("MYSQL_DATABASE"), (int)getenv("DB_PORT"));
if ($db->connect_error) { fwrite(STDERR, $db->connect_error . "\n"); exit(1); }
$db->close();
'; do
    echo "waiting for MariaDB..."
    sleep 2
done

if [ ! -f wp-config.php ]; then
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="$DB_HOST" \
        --allow-root
fi


if ! wp core is-installed --allow-root; then
    wp core install \
        --url="https://$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root
fi


wp config set WP_REDIS_HOST redis   --allow-root
wp config set WP_REDIS_PORT 6379 --raw --allow-root
wp config set WP_CACHE true --raw --allow-root


if ! wp plugin is-installed redis-cache --allow-root; then
    wp plugin install redis-cache --activate --allow-root
fi

wp redis enable --allow-root

exec php-fpm8.2 -F