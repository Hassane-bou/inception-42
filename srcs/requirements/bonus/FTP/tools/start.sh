#!/bin/bash

set -e

if ! id "$FTP_USER" > /dev/null 2>&1; then
    useradd -o -u 33 -g 33 -d /var/www/html -s /bin/bash "$FTP_USER"
fi

echo "$FTP_USER:$FTP_PASSWORD" | chpasswd


echo "pasv_address=${FTP_PASV_ADDRESS:-127.0.0.1}" >> /etc/vsftpd.conf

exec vsftpd /etc/vsftpd.conf