FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends nginx \
    &&  rm -f /etc/nginx/sites_enabled/default \
    && rm -rf /var/lib/apt/lists/*


COPY conf/default.conf  /etc/nginx/conf.d/default.conf
COPY site/ /var/www/static/

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]

