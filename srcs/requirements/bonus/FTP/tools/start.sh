#!/bin/bash

set -e

: "${FTP_USER:?FTP_USER is required}"
: "${FTP_PASSWORD:?FTP_PASSWORD is required}"


if ! id "$FTP_USER" > /dev/null 2>&1; then
    useradd -o -u 33 -g 33 -d /var/www/html -s /bin/bash "$FTP_USER" 2>/dev/null
fi

echo "$FTP_USER:$FTP_PASSWORD" | chpasswd


if [ -n "${FTP_PASV_ADDRESS:-}" ]; then
    sed -i '/^pasv_address=/d' /etc/vsftpd.conf
    echo "pasv_address=$FTP_PASV_ADDRESS" >> /etc/vsftpd.conf
fi


exec vsftpd /etc/vsftpd.conf