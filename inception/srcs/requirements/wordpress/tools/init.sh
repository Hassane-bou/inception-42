#!/bin/bash

set -e

cd /var/www/html

if [ ! -f wp-load.php ]; then
    wp core download --allow-root
fi

until php -r '
mysqli_report(MYSQLI_REPORT_OFF);
$db = @new mysqli(
    getenv("DB_HOST"),
    getenv("MYSQL_USER"),
    getenv("MYSQL_PASSWORD"),
    getenv("MYSQL_DATABASE")
);
if ($db->connect_error) {
    exit(1);
}
$db->close();
' ; do
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
        --url="$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --allow-root
fi

exec php-fpm8.2 -F