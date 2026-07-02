FROM debian:bookworm
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y mariadb-server && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/lib/mysql/*
COPY conf/mariadb.cnf  /etc/mysql/mariadb.conf.d/
COPY tools/setup.sh  /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh
EXPOSE 3306
ENTRYPOINT ["/usr/local/bin/setup.sh"]

