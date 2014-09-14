#!/bin/bash

if [ $(id -u) != "0" ]; then
    echo "This script must be run as root." 1>&2
    exit 1
fi

apt-get -y install php5 php5-cli php5-pgsql php5-mysql php5-curl php5-mcrypt php5-gd php5-imagick php5-fpm

# Enable mcrypt properly.
cp /etc/php5/conf.d/mcrypt.ini /etc/php5/mods-available/mcrypt.ini
php5enmod mcrypt

# Remove the default php-fpm pool.
rm -f /etc/php5/fpm/pool.d/www.conf
cp ./templates/php/www.conf /etc/php5/fpm/pool.d/www.conf
sed -i "s/{{ domain }}/testing.com/g" /etc/php5/fpm/pool.d/www.conf

# Create a location for php-fpm pool slowlogs.

# Create directories for php.
mkdir -p /var/log/php
mkdir -p /var/log/php-fpm
chown -R www-data /var/log/php
chown -R www-data /var/log/php-fpm

mkdir -p /var/lib/php/upload
mkdir -p /var/lib/php/session
chown -R www-data /var/lib/php

# Modify php ini settings for fpm.
PHPINI=/etc/php5/fpm/php.ini
sed -i 's/^display_errors = On/display_errors = Off/' $PHPINI
sed -i 's/^expose_php = On/expose_php = Off/' $PHPINI
sed -i 's/^;date.timezone =.*/date.timezone = UTC/' $PHPINI
sed -i 's/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' $PHPINI
sed -i 's@;error_log =.*@error_log = /var/log/php/error-fpm.log@' $PHPINI
sed -i 's@;upload_tmp_dir =.*@upload_tmp_dir = /var/lib/php/upload@' $PHPINI
sed -i 's@;session.save_path =.*@session.save_path = /var/lib/php/session@' $PHPINI

# Modify php ini settings for cli.
PHPINI=/etc/php5/cli/php.ini
sed -i 's/^;date.timezone =.*/date.timezone = UTC/' $PHPINI
sed -i 's@;error_log =.*@error_log = /var/log/php/error-cli.log@' $PHPINI

touch /tmp/restart-php5-fpm

exit 0