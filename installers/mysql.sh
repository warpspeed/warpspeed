#!/bin/bash

# Make sure warpspeed environment vars are available before proceeding.
if [ -z "$WARPSPEED_ROOT" ] || [ -z "$WARPSPEED_USER" ]; then
    echo "Error: It appears that this server was not provisioned with Warpspeed."
    echo "WARPSPEED_ROOT and WARPSPEED_USER env vars were not found."
    exit 1
fi

# Import the warpspeed functions.
source $WARPSPEED_ROOT/includes/functions.sh

# Require that the root user be executing this script.
ws_require_root


# todo, improve password handling
if [ -z "$PASSWORD" ]; then
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

# sed -i 's/^bind-address.*/bind-address = */' /etc/mysql/my.cnf
# mysql --user="root" --password="$MYSQLPASSWORD" -e "GRANT ALL ON *.* TO root@'$IPADDRESS' IDENTIFIED BY '$MYSQLPASSWORD';"
# mysql --user="root" --password="$MYSQLPASSWORD" -e "GRANT ALL ON *.* TO root@'%' IDENTIFIED BY '$MYSQLPASSWORD';"
# mysql --user="root" --password="$MYSQLPASSWORD" -e "GRANT ALL ON *.* TO warpspeed@'$IPADDRESS' IDENTIFIED BY '$MYSQLPASSWORD';"
# mysql --user="root" --password="$MYSQLPASSWORD" -e "GRANT ALL ON *.* TO warpspeed@'%' IDENTIFIED BY '$MYSQLPASSWORD';"
# mysql --user="root" --password="$MYSQLPASSWORD" -e "FLUSH PRIVILEGES;"

service mysql restart
