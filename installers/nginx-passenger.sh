#!/bin/bash

if [ $(id -u) != "0" ]; then
    echo "This script must be run as root." 1>&2
    exit 1
fi

INSTALLERS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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
cp $INSTALLERS_DIR/../templates/nginx/nginx.conf /etc/nginx/nginx.conf

# Create a location for nginx configuration includes and copy include templates.
mkdir -p /etc/nginx/includes
cp $INSTALLERS_DIR/../templates/nginx/location.conf /etc/nginx/includes/location.conf

touch /tmp/restart-nginx
