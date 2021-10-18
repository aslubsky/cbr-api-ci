FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

RUN apt-get update && apt-get -y upgrade

RUN apt-get install --fix-missing -y \
    curl \
    wget \
    dialog \
    git \
    supervisor \
    nano \
    ca-certificates \
    gnupg2 \
    apt-utils \
    debconf-utils \
    software-properties-common \
    lsb-release

RUN cd /tmp && wget https://github.com/htacg/tidy-html5/releases/download/5.4.0/tidy-5.4.0-64bit.deb && dpkg -i tidy-5.4.0-64bit.deb

#nodejs
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get update
RUN apt-get install -y nodejs

#php
RUN add-apt-repository ppa:ondrej/php
RUN apt-get update
RUN apt-get install -y libmcrypt-dev php7.3 php7.3-mysql php7.3-xml php7.3-curl php7.3-gd php7.3-intl php7.3-zip php7.3-mbstring php7.3-fpm php7.3-sqlite php7.3-ldap php7.3-redis php7.3-dev
RUN pecl install mcrypt-1.0.2
RUN echo "extension=mcrypt.so" > /etc/php/7.3/mods-available/mcrypt.ini
RUN ln -s /etc/php/7.3/mods-available/mcrypt.ini /etc/php/7.3/cli/conf.d/mcrypt.ini
RUN ln -s /etc/php/7.3/mods-available/mcrypt.ini /etc/php/7.3/fpm/conf.d/mcrypt.ini
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin
RUN /usr/bin/composer.phar self-update
RUN wget -O /usr/bin/phpunit https://phar.phpunit.de/phpunit-5.phar
RUN chmod +x /usr/bin/phpunit


#mysql
RUN cd /tmp && wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
RUN cd /tmp && dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
RUN percona-release enable-only ps-80 release
RUN apt-get update
RUN echo "percona-server-server percona-server-server/root-pass password tests" | debconf-set-selections
RUN echo "percona-server-server percona-server-server/re-root-pass password tests" | debconf-set-selections
RUN echo "percona-server-server percona-server-server/default-auth-override select Use Legacy Authentication Method (Retain MySQL 5.x Compatibility)" | debconf-set-selections
RUN apt-get install -y percona-server-server
COPY ./config/mysql/mysql.cnf /etc/mysql/mysql.conf.d/mysqld.cnf

##elasticsearch
#RUN echo "tzdata tzdata/Zones/Etc select UTC" | debconf-set-selections
#RUN rm -f /etc/timezone /etc/localtime
#RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime
#RUN apt-get -y install tzdata
#RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
#RUN echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-5.x.list
#RUN apt-get update
#RUN apt-get -y install openjdk-8-jdk elasticsearch
#COPY ./config/elasticsearch/elasticsearch.yml /usr/share/elasticsearch/config/elasticsearch.yml
#RUN ln -s /etc/elasticsearch /usr/share/elasticsearch/config
#COPY ./config/elasticsearch/limits.conf /etc/security/limits.conf
#RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-icu

#clickhouse
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv E0C56BD4
RUN echo "deb http://repo.yandex.ru/clickhouse/deb/stable/ main/" | tee /etc/apt/sources.list.d/clickhouse.list
RUN apt-get update
RUN echo "clickhouse-server clickhouse-server/default-password password tests" | debconf-set-selections
RUN apt-get install -y clickhouse-server=21.9.2.17 clickhouse-client=21.9.2.17 clickhouse-common-static=21.9.2.17
RUN setcap -r `which clickhouse` && echo "Cleaning caps success" || echo "Cleaning caps error"
#COPY ./config/clickhouse/users.xml /etc/clickhouse-server/users.xml
RUN sed -i "s|/var/lib/clickhouse/|/mnt/tmpfs/clickhouse/|g" /etc/clickhouse-server/config.xml
RUN sed -i "s|<tcp_port>9000</tcp_port>|<tcp_port>9002</tcp_port>|g" /etc/clickhouse-server/config.xml

#redis
RUN apt install -y redis-server
COPY ./config/redis/redis.conf /etc/redis/redis.conf

#nats
RUN cd /tmp && wget https://github.com/nats-io/nats-server/releases/download/v2.6.1/nats-server-v2.6.1-amd64.deb
RUN dpkg -i /tmp/nats-server-v2.6.1-amd64.deb
#add config here

##minio
RUN wget https://dl.min.io/server/minio/release/linux-amd64/minio -O /usr/bin/minio
#COPY ./minio /usr/bin/minio
RUN chmod +x /usr/bin/minio

RUN mkdir -p /var/log/supervisor
COPY ./config/supervisord /etc/supervisor/conf.d

COPY ./config/entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

#
# Remove the packages that are no longer required after the package has been installed
RUN apt-get autoremove --purge -q -y
RUN apt-get autoclean -y -q
RUN apt-get clean -y

