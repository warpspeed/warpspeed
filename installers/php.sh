#!/bin/bash

if [ $(id -u) != "0" ]; then
    echo "This script must be run as root." 1>&2
    exit 1
fi

apt-get -y install php5 php5-cli php5-pgsql php5-mysql php5-curl php5-mcrypt php5-gd php5-imagick php5-fpm

# Remove the default php-fpm pool.
mv -f /etc/php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d/www.conf.orig

# Create directory for logging.
mkdir -p /var/log/php
chown -R www-data:www-data /var/log/php

# Create directory for uploads and sessions.
mkdir -p /var/lib/php
chown -R www-data:www-data /var/lib/php

# Backup original and then modify php ini settings for fpm.
PHPINI=/etc/php5/fpm/php.ini
cp $PHPINI $PHPINI.orig
sed -i 's/^display_errors = On/display_errors = Off/' $PHPINI
sed -i 's/^expose_php = On/expose_php = Off/' $PHPINI
sed -i 's/^;date.timezone =.*/date.timezone = UTC/' $PHPINI
sed -i 's/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' $PHPINI

# Backup original and then modify php ini settings for cli.
PHPINI=/etc/php5/cli/php.ini
cp $PHPINI $PHPINI.orig
sed -i 's/^;date.timezone =.*/date.timezone = UTC/' $PHPINI
sed -i 's@;error_log =.*@error_log = /var/log/php/error-cli.log@' $PHPINI

# Ensure that mcrypt is enabled
php5enmod mcrypt

# Download and install composer globally
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

touch /tmp/restart-php5-fpm
