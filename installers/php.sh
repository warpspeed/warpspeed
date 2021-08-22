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

ws_log_header "Installing php7.4."

apt-get -y install php7.4 php7.4-cli php7.4-curl php7.4-dev php7.4-fpm php7.4-gd php7.4-imagick php7.4-imap php7.4-intl php7.4-mbstring php7.4-memcached php7.4-mongodb php7.4-mysql php7.4-pgsql php7.4-zip

# Install debug tools only for vagrant environment.
if [ $WARPSPEED_USER == "vagrant" ]; then
    apt-get -y install php7.4-xdebug
fi

# Remove the default php-fpm pool.
mv -f /etc/php/7.4/fpm/pool.d/www.conf /etc/php/7.4/fpm/pool.d/www.conf.orig

# Create directory for logging.
mkdir -p /var/log/php
chown -R $WARPSPEED_USER:www-data /var/log/php

# Create directory for uploads and sessions.
mkdir -p /var/lib/php
chown -R $WARPSPEED_USER:www-data /var/lib/php

# Backup original and then modify php ini settings for fpm.
PHPINI=/etc/php/7.4/fpm/php.ini
cp $PHPINI $PHPINI.orig
sed -i 's/^display_errors = On/display_errors = Off/' $PHPINI
sed -i 's/^expose_php = On/expose_php = Off/' $PHPINI
sed -i 's/^;date.timezone =.*/date.timezone = UTC/' $PHPINI
sed -i 's/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' $PHPINI

# Backup original and then modify php ini settings for cli.
PHPINI=/etc/php/7.4/cli/php.ini
cp $PHPINI $PHPINI.orig
sed -i 's/^;date.timezone =.*/date.timezone = UTC/' $PHPINI
sed -i 's@;error_log =.*@error_log = /var/log/php/error-cli.log@' $PHPINI

# Download and install composer globally.
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Stop the service and remove startup files.
service php7.4-fpm stop
systemctl disable php7.4-fpm
