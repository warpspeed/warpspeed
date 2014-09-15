#!/bin/bash

if [ $(id -u) != "0" ]; then
    echo "This script must be run as root." 1>&2
    exit 1
fi

INSTALLERS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Install nginx ppa for more frequent updates.
apt-add-repository -y ppa:nginx/stable
apt-get update

apt-get -y install nginx

# Disable and remove default site.
#rm -f /etc/nginx/sites-enabled/default
#rm -f /etc/nginx/sites-available/default

# Create a location for site specific log files.
mkdir -p /var/log/nginx

# Copy nginx config template.
cp $INSTALLERS_DIR/../templates/nginx/nginx.conf /etc/nginx/nginx.conf

# Create a location for nginx configuration includes and copy include templates.
mkdir -p /etc/nginx/includes
cp $INSTALLERS_DIR/../templates/nginx/location.conf /etc/nginx/includes/location.conf

touch /tmp/restart-nginx
