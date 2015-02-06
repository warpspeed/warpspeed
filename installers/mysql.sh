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

ws_log_header "Installing mysql."

# Obtain password from environment or parameter.
if [ -z "$DB_PASSWORD" ]; then
    if [ -z "$1" ]; then
        # Password must be set or passed in, warn and exit.
        echo "Usage: $0 password"
        exit 1
    else
        DB_PASSWORD="$1"
    fi
fi

# Obtain system IP address.
IPADDRESS=$(ifconfig eth0 | awk -F: '/inet addr:/ {print $2}' | awk '{ print $1 }')

# Pre-set root password.
debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_PASSWORD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_PASSWORD"

# Install mysql.
apt-get -y install mysql-server mysql-client libmysqlclient-dev

# Configure mysql installation for remote access.
sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
mysql --user="root" --password="$DB_PASSWORD" -e "GRANT ALL ON *.* TO root@'%' IDENTIFIED BY '$DB_PASSWORD';FLUSH PRIVILEGES;"

# Create warpspeed user.
mysql --user="root" --password="$DB_PASSWORD" -e "CREATE USER '$WARPSPEED_USER'@'$IPADDRESS' IDENTIFIED BY '$DB_PASSWORD';"
mysql --user="root" --password="$DB_PASSWORD" -e "GRANT ALL ON *.* TO '$WARPSPEED_USER'@'$IPADDRESS' IDENTIFIED BY '$DB_PASSWORD' WITH GRANT OPTION;"
mysql --user="root" --password="$DB_PASSWORD" -e "GRANT ALL ON *.* TO '$WARPSPEED_USER'@'%' IDENTIFIED BY '$DB_PASSWORD' WITH GRANT OPTION;"
mysql --user="root" --password="$DB_PASSWORD" -e "FLUSH PRIVILEGES;"

# Create sample database.
mysql --user="root" --password="$DB_PASSWORD" -e "CREATE DATABASE $WARPSPEED_USER;"

# Restart the db server.
service mysql restart
