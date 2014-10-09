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

# todo work out password issue

aptitude -y install postgresql postgresql-contrib

# sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.3/main/postgresql.conf
# echo "host    all             all             0.0.0.0/0               md5" | tee -a /etc/postgresql/9.3/main/pg_hba.conf
# sudo -u postgres psql -c "CREATE ROLE warpspeed LOGIN UNENCRYPTED PASSWORD '$1' SUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;"

service postgresql restart
