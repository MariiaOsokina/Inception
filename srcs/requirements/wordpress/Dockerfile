FROM debian:bookworm
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y php-fpm php-mysqli wget ca-certificates mariadb-client && \
    rm -rf /var/lib/apt/lists/*
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp
RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh
EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/setup.sh"]

