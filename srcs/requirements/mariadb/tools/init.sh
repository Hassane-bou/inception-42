#!/bin/bash

if [ ! -d "/var/lib/mysql/mysql" ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql
fi

mariadbd --user=mysql &

until mariadb -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1" >/dev/null 2>&1
do
    sleep 1
done

if [ ! -f "/var/lib/mysql/.initialized" ]; then

    mariadb -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';

CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;
EOF

    touch /var/lib/mysql/.initialized

fi

mysqladmin -u root -p"$MYSQL_ROOT_PASSWORD"  shutdown

exec mariadbd --user=mysql