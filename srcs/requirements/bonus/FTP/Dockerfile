FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends vsftpd \
    && mkdir -p /var/run/vsftpd/empty \
    && rm -rf /var/lib/apt/lists/*

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/start.sh /usr/local/bin/start.sh

RUN chmod +x /usr/local/bin/start.sh

EXPOSE 21 40000-40010

CMD ["/usr/local/bin/start.sh"]