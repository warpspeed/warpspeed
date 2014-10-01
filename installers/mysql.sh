#!/bin/bash

if [ $(id -u) != "0" ]; then
    echo "This script must be run as root." 1>&2
    exit 1
fi

if [ -z "$1" ]; then
  echo "Usage: mysql.sh root-password"
  exit 1
fi

INSTALLERS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

debconf-set-selections <<< "mysql-server mysql-server/root_password password $1"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $1"

apt-get -y install mysql-server

php -v > /dev/null 2>&1
PHP_INSTALLED=$?

if [ $PHP_INSTALLED -eq 0 ]; then
    apt-get -y install php5-mysql
    service php5-fpm restart
fi
