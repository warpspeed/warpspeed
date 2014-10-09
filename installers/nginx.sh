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

# Add phusion APT repository.
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
apt-get -y install apt-transport-https ca-certificates
echo 'deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main' >> /etc/apt/sources.list.d/passenger.list
chmod 600 /etc/apt/sources.list.d/passenger.list
apt-get update

# Install nginx and passenger.
apt-get -y install nginx-full passenger

# Disable the default site.
rm -f /etc/nginx/sites-enabled/default

# Create a location for site specific log files.
mkdir -p /var/log/nginx

# Backup original nginx config and use template version.
mv -f /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
cp $WARPSPEED_ROOT/templates/nginx/nginx.conf /etc/nginx/nginx.conf

# Create a location for nginx configuration includes and copy include templates.
mkdir -p /etc/nginx/includes
cp $WARPSPEED_ROOT/templates/nginx/location.conf /etc/nginx/includes/location.conf

service nginx restart
