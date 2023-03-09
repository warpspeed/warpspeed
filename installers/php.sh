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

ws_log_header "Installing php8.2."


apt update
apt install -y ca-certificates apt-transport-https software-properties-common

add-apt-repository -y ppa:ondrej/php


apt install -y php8.2 php8.2-cli php8.2-curl php8.2-dev php8.2-fpm php8.2-gd php8.2-imagick php8.2-imap php8.2-intl php8.2-mbstring php8.2-memcached php8.2-mongodb php8.2-mysql php8.2-pgsql php8.2-zip

sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf

# Install debug tools only for vagrant environment.
if [ $WARPSPEED_USER == "vagrant" ]; then
    apt-get -y install php8.2-xdebug
fi

# Remove the default php-fpm pool.
mv -f /etc/php/8.2/fpm/pool.d/www.conf /etc/php/8.2/fpm/pool.d/www.conf.orig

# Create directory for logging.
mkdir -p /var/log/php
chown -R $WARPSPEED_USER:www-data /var/log/php

# Create directory for uploads and sessions.
mkdir -p /var/lib/php
chown -R $WARPSPEED_USER:www-data /var/lib/php

# Backup original and then modify php ini settings for fpm.
PHPINI=/etc/php/8.2/fpm/php.ini
cp $PHPINI $PHPINI.orig
sed -i 's/^display_errors = On/display_errors = Off/' $PHPINI
sed -i 's/^expose_php = On/expose_php = Off/' $PHPINI
sed -i 's/^;date.timezone =.*/date.timezone = UTC/' $PHPINI
sed -i 's/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' $PHPINI

# Backup original and then modify php ini settings for cli.
PHPINI=/etc/php/8.2/cli/php.ini
cp $PHPINI $PHPINI.orig
sed -i 's/^;date.timezone =.*/date.timezone = UTC/' $PHPINI
sed -i 's@;error_log =.*@error_log = /var/log/php/error-cli.log@' $PHPINI

# Download and install composer globally.
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Stop the service and remove startup files.
service php8.2-fpm stop
systemctl disable php8.2-fpm
