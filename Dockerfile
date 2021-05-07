#Get os image
FROM debian:buster

ENV AUTOINDEX on
ENV DOCUMENTROOT /var/www/html
#Install tools
RUN set -ex; \
apt update; \
apt install -y --no-install-recommends \
vim \
wget \
nginx \
php7.3 php7.3-fpm php-mysql \
default-mysql-server \
openssl \
ca-certificates; \
rm -rf /var/lib/apt/lists/*

#Setup mysql
RUN service mysql start; \
mysql -e "create database wordpress;"; \
mysql -e "grant all on wordpress.* to dbuser@localhost identified by 'pass'";
#Setup ssl
RUN mkdir /etc/nginx/ssl; \
openssl genrsa -out /etc/nginx/ssl/server.key 2048; \
openssl req -new -key /etc/nginx/ssl/server.key -out /etc/nginx/ssl/server.csr \
-subj "/C=JP/ST=Tokyo/L=Minato/O=42Tokyo/OU=42Cursus/CN=localhost"; \
openssl x509 -days 3650 -req -signkey /etc/nginx/ssl/server.key \
-in /etc/nginx/ssl/server.csr -out /etc/nginx/ssl/server.crt;
#Install phpmyadmin
RUN wget https://files.phpmyadmin.net/phpMyAdmin/5.0.4/phpMyAdmin-5.0.4-all-languages.tar.gz; \
tar -xvf phpMyAdmin-5.0.4-all-languages.tar.gz -C "$DOCUMENTROOT"; \
mv "$DOCUMENTROOT/phpMyAdmin-5.0.4-all-languages" "$DOCUMENTROOT/phpmyadmin"; \
rm phpMyAdmin-5.0.4-all-languages.tar.gz;
#Install WordPress
RUN wget https://wordpress.org/latest.tar.gz; \
tar -xvf latest.tar.gz -C "$DOCUMENTROOT"; \
rm latest.tar.gz;
#Copy Config Files
COPY ./srcs/wp-config.php /var/www/html/wordpress/wp-config.php
COPY ./srcs/default /etc/nginx/sites-available/default
COPY ./srcs/autoindex.sh ./
#End
CMD bash ./autoindex.sh; \
service mysql start; \
service php7.3-fpm start; \
service nginx start; \
tail -f /dev/null
