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

ws_log_header "Installing php8.0."

LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php
apt-get update

apt-get -y install php8.0 php8.0-cli php8.0-curl php8.0-dev php8.0-fpm php8.0-gd php8.0-imagick php8.0-imap php8.0-intl php8.0-mbstring php8.0-memcached php8.0-mongodb php8.0-mysql php8.0-pgsql php8.0-zip

# Install debug tools only for vagrant environment.
if [ $WARPSPEED_USER == "vagrant" ]; then
    apt-get -y install php8.0-xdebug
fi

# Remove the default php-fpm pool.
mv -f /etc/php/8.0/fpm/pool.d/www.conf /etc/php/8.0/fpm/pool.d/www.conf.orig

# Create directory for logging.
mkdir -p /var/log/php
chown -R $WARPSPEED_USER:www-data /var/log/php

# Create directory for uploads and sessions.
mkdir -p /var/lib/php
chown -R $WARPSPEED_USER:www-data /var/lib/php

# Install mcrypt.
apt-get -y install php-pecl
apt-get -y install gcc make autoconf libc-dev pkg-config
apt-get -y install libmcrypt-dev
yes '' | pecl install mcrypt-1.0.4

# Backup original and then modify php ini settings for fpm.
PHPINI=/etc/php/8.0/fpm/php.ini
cp $PHPINI $PHPINI.orig
sed -i 's/^display_errors = On/display_errors = Off/' $PHPINI
sed -i 's/^expose_php = On/expose_php = Off/' $PHPINI
sed -i 's/^;date.timezone =.*/date.timezone = UTC/' $PHPINI
sed -i 's/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' $PHPINI
echo 'extension=mcrypt.so' >> $PHPINI

# Backup original and then modify php ini settings for cli.
PHPINI=/etc/php/8.0/cli/php.ini
cp $PHPINI $PHPINI.orig
sed -i 's/^;date.timezone =.*/date.timezone = UTC/' $PHPINI
sed -i 's@;error_log =.*@error_log = /var/log/php/error-cli.log@' $PHPINI
echo 'extension=mcrypt.so' >> $PHPINI

# Download and install composer globally.
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Stop the service and remove startup files.
service php8.0-fpm stop
systemctl disable php8.0-fpm
