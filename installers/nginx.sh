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

ws_log_header "Installing nginx."

apt update
apt install -y ca-certificates apt-transport-https software-properties-common

add-apt-repository -y ppa:ondrej/nginx

apt install -y nginx

# Disable the default site and back up the config.
rm -f /etc/nginx/sites-enabled/default
mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.sample

# Copy the warpspeed default site config and enable it.
cp $WARPSPEED_ROOT/templates/nginx/default /etc/nginx/sites-available/default
ln -fs /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Create a location for site specific log files.
mkdir -p /var/log/nginx

# Backup original nginx config and use template version.
mv -f /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
cp $WARPSPEED_ROOT/templates/nginx/nginx.conf /etc/nginx/nginx.conf
sed -i "s/{{user}}/$WARPSPEED_USER/g" /etc/nginx/nginx.conf

service nginx restart
