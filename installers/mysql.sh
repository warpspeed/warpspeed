#!/bin/bash

if [ $(id -u) != "0" ]; then
    echo "This script must be run as root." 1>&2
    exit 1
fi

if [ -z "$PASSWORD"]; then
    if [ -z "$1" ]; then
        # Password to add to mysql root user must be set or passed in.
        echo "Usage: $0 password"
        exit 1
    else
        MYSQLPASSWORD="$1"
    fi
else
    MYSQLPASSWORD="$PASSWORD"
fi

IPADDRESS=$(ifconfig eth0 | awk -F: '/inet addr:/ {print $2}' | awk '{ print $1 }')

debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQLPASSWORD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQLPASSWORD"

apt-get -y install mysql-server

php -v > /dev/null 2>&1
PHP_INSTALLED=$?

if [ $PHP_INSTALLED -eq 0 ]; then
    apt-get -y install php5-mysql
    service php5-fpm restart
fi
