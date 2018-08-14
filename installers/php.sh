#!/bin/bash

# Make sure warpspeed environment vars are available before proceeding.
if [ -z "$WARPSPEED_ROOT" ] || [ -z "$WARPSPEED_USER" ]; then
    echo "Error: It appears that this server was not provisioned with Warpspeed."
    echo "WARPSPEED_ROOT and WARPSPEED_USER env vars were not found."
    exit 1
fi

# Import the warpspeed functions.
source $WARPSPEED_ROOT/includes/installer-functions.sh

# Require that the root user be executing this script.
ws_require_root

ws_log_header "Installing php."

apt-get -y install php-fpm php-cli php-pgsql php-mysql php-mongodb php-curl php-gd php-imagick php-fpm php-memcached php-dev php-json php-zip php-intl php-imap php-mbstring

# Install debug tools only for vagrant environment.
if [ $WARPSPEED_USER == "vagrant" ]; then
    apt-get -y install php-xdebug
fi

# Remove the default php-fpm pool.
mv -f /etc/php/7.2/fpm/pool.d/www.conf /etc/php/7.2/fpm/pool.d/www.conf.orig

# Create directory for logging.
mkdir -p /var/log/php
chown -R $WARPSPEED_USER:www-data /var/log/php

# Create directory for uploads and sessions.
mkdir -p /var/lib/php
chown -R $WARPSPEED_USER:www-data /var/lib/php

# Backup original and then modify php ini settings for fpm.
PHPINI=/etc/php/7.2/fpm/php.ini
cp $PHPINI $PHPINI.orig
sed -i 's/^display_errors = On/display_errors = Off/' $PHPINI
sed -i 's/^expose_php = On/expose_php = Off/' $PHPINI
sed -i 's/^;date.timezone =.*/date.timezone = UTC/' $PHPINI
sed -i 's/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' $PHPINI

# Backup original and then modify php ini settings for cli.
PHPINI=/etc/php/7.2/cli/php.ini
cp $PHPINI $PHPINI.orig
sed -i 's/^;date.timezone =.*/date.timezone = UTC/' $PHPINI
sed -i 's@;error_log =.*@error_log = /var/log/php/error-cli.log@' $PHPINI

# Download and install composer globally.
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Stop the service and remove startup files.
service php7.2-fpm stop
systemctl disable php7.2-fpm
