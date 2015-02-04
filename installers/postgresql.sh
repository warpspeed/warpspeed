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

# Add postgresql APT repository.
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" | tee -a /etc/apt/sources.list.d/pgdg.list
chmod 644 /etc/apt/sources.list.d/pgdg.list
apt-get update

# Install postgresql 9.4.
apt-get -y install postgresql-9.4 postgresql-contrib libpq-dev

# Configure postgres installation for remote access and password authentication.
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.4/main/postgresql.conf
echo "host    all             all             0.0.0.0/0               md5" | tee -a /etc/postgresql/9.4/main/pg_hba.conf

# Create warpspeed user.
sudo -u postgres psql -c "CREATE ROLE warpspeed LOGIN UNENCRYPTED PASSWORD '$DB_PASSWORD' SUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;"

# Create sample database.
sudo -u postgres createdb --owner=warpspeed warpspeed

# Restart the db server.
service postgresql restart
