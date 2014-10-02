#!/bin/bash

if [ $(id -u) != "0" ]; then
    echo "This script must be run as root." 1>&2
    exit 1
fi

aptitude -y install postgresql postgresql-contrib

php -v > /dev/null 2>&1
PHP_INSTALLED=$?

if [ PHP_INSTALLED -eq 0 ]; then
    apt-get -y install php5-pgsql
    service php5-fpm restart
fi
