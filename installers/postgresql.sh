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

ws_log_header "Installing postgresql."

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

# Install postgresql.
apt-get -y install postgresql postgresql-contrib libpq-dev

# Configure postgres installation for remote access and password authentication.
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.5/main/postgresql.conf
echo "host    all             all             0.0.0.0/0               md5" | tee -a /etc/postgresql/9.5/main/pg_hba.conf

# Create warpspeed user.
sudo -u postgres psql -c "CREATE ROLE $WARPSPEED_USER LOGIN UNENCRYPTED PASSWORD '$DB_PASSWORD' SUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;"

# Create sample database.
sudo -u postgres createdb --owner=$WARPSPEED_USER $WARPSPEED_USER

# Restart the db server.
service postgresql restart
