#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 hostname"
  exit 1
fi

HELPERS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

USER=warpspeed

# If the vagrant home directory exists, assume we are using vagrant.
if [ -d "/home/vagrant" ]; then
	USER=vagrant
fi

# Make sure the site doesn't already exist.
if [ -d "/home/$USER/sites/$1" ]; then
  echo "Error: The site /home/$USER/sites/$1 already exists."
  exit 1
fi

echo "Creating site..."

# Create the site directory.
sudo -u $USER mkdir -p "/home/$USER/sites/$1"
sudo -u $USER mkdir -p "/home/$USER/sites/$1/public"
sudo -u $USER mkdir -p "/home/$USER/sites/$1/tmp"

# Configure nginx to serve the new site.
sudo cp $HELPERS_DIR/../templates/nginx/site-python.conf /etc/nginx/sites-available/$1
sudo sed -i "s/{{domain}}/$1/g" /etc/nginx/sites-available/$1
sudo sed -i "s/{{user}}/$USER/g" /etc/nginx/sites-available/$1
sudo ln -s /etc/nginx/sites-available/$1 /etc/nginx/sites-enabled/$1

cp $HELPERS_DIR/../templates/ruby/config.ru /home/$USER/sites/$1

sudo service nginx reload
