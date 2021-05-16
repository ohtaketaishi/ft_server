#Get os image
FROM debian:buster

ENV AUTOINDEX on
ENV DOCUMENTROOT /var/www/html
#Install tools
RUN set -ex; \
apt-get update; \
apt-get install -y --no-install-recommends \
vim \
wget \
nginx \
php7.3 php7.3-fpm php-mysql php7.3-xml php-mbstring \
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
RUN wget https://files.phpmyadmin.net/phpMyAdmin/5.1.0/phpMyAdmin-5.1.0-all-languages.tar.gz; \
tar -xvf phpMyAdmin-5.1.0-all-languages.tar.gz -C "$DOCUMENTROOT"; \
mv "$DOCUMENTROOT/phpMyAdmin-5.1.0-all-languages" "$DOCUMENTROOT/phpmyadmin"; \
rm phpMyAdmin-5.1.0-all-languages.tar.gz; \
chown -R www-data:www-data "$DOCUMENTROOT/phpmyadmin";
#Install WordPress
RUN wget https://wordpress.org/latest.tar.gz; \
tar -xvf latest.tar.gz -C "$DOCUMENTROOT"; \
rm latest.tar.gz; \
chown -R www-data:www-data "$DOCUMENTROOT/wordpress";
#Copy Config Files
COPY ./srcs/wp-config.php /var/www/html/wordpress/wp-config.php
COPY ./srcs/config.inc.php /var/www/html/phpmyadmin/config.inc.php
COPY ./srcs/default /etc/nginx/sites-available/default
COPY ./srcs/autoindex.sh ./
#For VM
RUN chown www-data:www-data "$DOCUMENTROOT/wordpress/wp-config.php";
RUN chmod 777 "$DOCUMENTROOT/wordpress/wp-config.php";
RUN chown www-data:www-data "$DOCUMENTROOT/phpmyadmin/config.inc.php";
RUN chmod 755 "$DOCUMENTROOT/phpmyadmin/config.inc.php";
#Expose
Expose 80 443
#End
CMD bash ./autoindex.sh; \
service mysql start; \
service php7.3-fpm start; \
service nginx start; \
tail -f /dev/null
