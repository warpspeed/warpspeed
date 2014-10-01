#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: site-create-php.sh hostname"
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

# Configure nginx to serve the new site.
sudo cp $HELPERS_DIR/../templates/nginx/site-php.conf /etc/nginx/sites-available/$1
sudo sed -i "s/{{domain}}/$1/g" /etc/nginx/sites-available/$1
sudo sed -i "s/{{user}}/$USER/g" /etc/nginx/sites-available/$1
sudo ln -s /etc/nginx/sites-available/$1 /etc/nginx/sites-enabled/$1

# Setup a site specific php-fpm pool.
sudo cp $HELPERS_DIR/../templates/php/www.conf /etc/php5/fpm/pool.d/$1.conf
sudo sed -i "s/{{domain}}/$1/g" /etc/php5/fpm/pool.d/$1.conf
sudo sed -i "s/{{user}}/$USER/g" /etc/php5/fpm/pool.d/$1.conf

# Create site specific directories for uploads and sessions.
sudo mkdir -p /var/lib/php/$1/upload
sudo mkdir -p /var/lib/php/$1/session
sudo chown -R www-data:www-data /var/lib/php/$1

# Create a git repo for push deploy unless we are on a vagrant box.
if [ $USER != "vagrant" ]; then
	
	sudo -u $USER mkdir -p "/home/$USER/repos/$1.git"

	cd "/home/$USER/repos/$1.git"
	sudo -u $USER git init --bare
	sudo -u $USER cp $HELPERS_DIR/../templates/git/post-receive /home/$USER/repos/$1.git/hooks/post-receive
	sudo sed -i "s/{{domain}}/$1/g" /home/$USER/repos/$1.git/hooks/post-receive
	sudo sed -i "s/{{user}}/$USER/g" /home/$USER/repos/$1.git/hooks/post-receive
	sudo chmod +x "/home/$USER/repos/$1.git/hooks/post-receive"

	echo "Use: git remote add web ssh://$USER@$1/home/$user/repos/$1.git"
	echo "and: git push web +master:refs/heads/master"

fi

# Restart services.
sudo service nginx reload
sudo service php5-fpm restart

echo "Site setup is complete for: /home/$USER/sites/$1"
