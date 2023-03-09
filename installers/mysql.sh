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

# Install mysql.
apt install -y mysql-server

# Root starts out with no password. Create a new warpspeed superuser.
mysql -e "CREATE USER '$WARPSPEED_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
mysql -e "GRANT ALL ON *.* TO '$WARPSPEED_USER'@'localhost' WITH GRANT OPTION;FLUSH PRIVILEGES;"

# Drop the root user.
mysql -e "DROP USER 'root'@'localhost';FLUSH PRIVILEGES;"
# If you'd prefer to keep the root user, comment out drop command and uncomment this alter password command.
# mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$DB_PASSWORD';FLUSH PRIVILEGES;"

# Start and enable service.
systemctl start mysql
systemctl enable mysql
