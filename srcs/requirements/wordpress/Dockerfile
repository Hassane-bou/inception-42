FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    php8.2-redis \
    php-fpm \
    php-mysql \
    php-cli \
    curl \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* 

RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    -O /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/init.sh /usr/local/bin/init.sh

RUN chmod +x /usr/local/bin/init.sh

CMD ["/usr/local/bin/init.sh"]