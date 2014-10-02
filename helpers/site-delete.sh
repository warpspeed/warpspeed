#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 hostname"
  exit 1
fi

USER=warpspeed

# If the vagrant home directory exists, assume we are using vagrant.
if [ -d "/home/vagrant" ]; then
	USER=vagrant
fi

# Make sure the site exists
if [ ! -d "/home/$USER/sites/$1" ]; then
  echo "Error: The site /home/$USER/sites/$1 does not exist."
  exit 1
fi

rm -rf /home/$USER/sites/$1
rm -rf /home/$USER/repos/$1.git

sudo rm -f /etc/nginx/sites-enabled/$1
sudo rm -f /etc/nginx/sites-available/$1

sudo rm -rf /var/lib/php/$1
sudo rm -f /var/log/php/$1-*.log
sudo rm -f /etc/php5/fpm/pool.d/$1.conf

# Restart services.
sudo service nginx reload
sudo service php5-fpm restart

echo "All files for site $1 have been removed."
