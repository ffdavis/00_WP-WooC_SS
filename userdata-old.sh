#!/bin/bash

STOREONEEC2DNSNAME=$1

sudo su <<EOF
set -x
exec &>> /home/ubuntu/userdata.log 2>&1

echo "*****************"
echo "* userdata-start "
echo "*****************"
echo ""
echo "STEP 1 - PREPARE AND UPDATE UBUNTU"
echo "-------------------------------------------------------------------------------------------"
echo ""
rm -f /etc/localtime
ln -sf /usr/share/zoneinfo/America/Santiago /etc/localtime

apt update -y 
# apt full-upgrade -y 
DEBIAN_FRONTEND=noninteractive apt -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" full-upgrade
apt autoremove -y

echo ""
echo "STEP 2 - INSTALL APACHE2 WEB SERVER"
echo "-------------------------------------------------------------------------------------------"
apt install apache2 -y
sed -i "s/Options Indexes FollowSymLinks/Options FollowSymLinks/" /etc/apache2/apache2.conf
systemctl stop apache2.service
systemctl start apache2.service
systemctl enable apache2.service

echo ""
echo "STEP 3: INSTALL MARIADB DATABASE SERVER"
echo "-------------------------------------------------------------------------------------------"
apt-get install mariadb-server mariadb-client -y
systemctl stop mariadb.service
systemctl start mariadb.service
systemctl enable mariadb.service
mysql_secure_installation <<EOF-MYSQLSECINST

y
cacarulo99
cacarulo99
y
y
y
y
EOF-MYSQLSECINST

echo ""
echo "STEP 4: INSTALL PHP AND RELATED MODULES"
echo "-------------------------------------------------------------------------------------------"
apt install -y php
apt install -y libapache2-mod-php
apt install -y php-common
apt install -y php-mbstring
apt install -y php-xmlrpc
apt install -y php-soap
apt install -y php-gd
apt install -y php-xml
apt install -y php-intl
apt install -y php-mysql
apt install -y php-cli

# Replace this "apt install -y php-mcrypt" for:
apt install -y php-dev 
apt install -y libmcrypt-dev 
apt install -y php-pear
pecl channel-update pecl.php.net
# pecl install mcrypt-1.0.1
# libmcrypt prefix? [autodetect] :
cat <(echo "") | pecl install mcrypt-1.0.1

# Open the /etc/php/7.2/cli/php.ini file and insert:
# extension=mcrypt.so
# or
sed -i "s/;extension=xsl/;extension=xsl \nextension=mcrypt.so/" /etc/php/7.2/cli/php.ini
sed -i "s/;extension=xsl/;extension=xsl \nextension=mcrypt.so/" /etc/php/7.2/apache2/php.ini
php -m | grep mcrypt

apt install -y php-ldap
apt install -y php-zip
apt install -y php-curl

sed -i "s/post_max_size = 8M/post_max_size = 100M/" /etc/php/7.2/cli/php.ini
sed -i "s/memory_limit = 128M/memory_limit = 256M/" /etc/php/7.2/cli/php.ini
sed -i "s/max_execution_time = 30/max_execution_time = 360/" /etc/php/7.2/cli/php.ini
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 100M/" /etc/php/7.2/cli/php.ini

sed -i "s/post_max_size = 8M/post_max_size = 100M/" /etc/php/7.2/apache2/php.ini
sed -i "s/memory_limit = 128M/memory_limit = 256M/" /etc/php/7.2/apache2/php.ini
sed -i "s/max_execution_time = 30/max_execution_time = 360/" /etc/php/7.2/apache2/php.ini
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 100M/" /etc/php/7.2/apache2/php.ini

echo ""
echo " STEP 5: CREATE A BLANK WORDPRESS DATABASE"
echo "-------------------------------------------------------------------------------------------"
/usr/bin/mysql -u root -pcacarulo99 <<_EOF_
CREATE DATABASE WP_database;
CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'cacarulo99';
GRANT ALL ON WP_database.* TO 'wp_user'@'localhost' IDENTIFIED BY 'cacarulo99';
FLUSH PRIVILEGES;
_EOF_

echo ""
echo " STEP 6: CONFIGURE THE NEW WORDPRESS SITE"
echo "-------------------------------------------------------------------------------------------"

cat <<EOT_wordpress_conf >> /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
     ServerAdmin ffdavis@outlook.com
     DocumentRoot /var/www/html/wordpress/
     ServerName ${STOREONEEC2DNSNAME}
     ServerAlias www.${STOREONEEC2DNSNAME}

     <Directory /var/www/html/wordpress/>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
     </Directory>

     ErrorLog /var/log/apache2/error.log
     CustomLog /var/log/apache2/access.log combined
</VirtualHost>
EOT_wordpress_conf

echo ""
echo " STEP 7: ENABLE THE WORDPRESS SITE AND REWRITE MODULE"
echo "-------------------------------------------------------------------------------------------"
a2ensite wordpress.conf
a2enmod rewrite

echo ""
echo " STEP 8: DOWNLOAD WORDPRESS LATEST RELEASE "
echo "-------------------------------------------------------------------------------------------"

cd /tmp && wget https://wordpress.org/latest.tar.gz
tar -zxvf latest.tar.gz
mv wordpress /var/www/html/wordpress

chown -R www-data:www-data /var/www/html/wordpress/
chmod -R 755 /var/www/html/wordpress/

echo ""
echo " STEP 9: CONFIGURE WORDPRESS "
echo "-------------------------------------------------------------------------------------------"

mv /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php

sed -i "s/define( 'DB_NAME', 'database_name_here' );/define('DB_NAME', 'WP_database');/" /var/www/html/wordpress/wp-config.php
sed -i "s/define( 'DB_USER', 'username_here' );/define('DB_USER', 'wp_user');/" /var/www/html/wordpress/wp-config.php
sed -i "s/define( 'DB_PASSWORD', 'password_here' );/define('DB_PASSWORD', 'cacarulo99');/" /var/www/html/wordpress/wp-config.php
sed -i "s/define( 'DB_HOST', 'localhost' );/define( 'DB_HOST', 'localhost' );/" /var/www/html/wordpress/wp-config.php

systemctl reload apache2.service

echo "*****************"
echo "* userdata-stop  "
echo "*****************"

EOF

echo ""
echo " STEP 10: INSTALL WP-CLI "
echo "-------------------------------------------------------------------------------------------"

