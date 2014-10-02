#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: site-create-python.sh hostname"
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

cp $HELPERS_DIR/../templates/python/passenger_wsgi.py /home/$USER/sites/$1/passenger_wsgi.py

sudo service nginx reload

# https://www.digitalocean.com/community/tutorials/how-to-deploy-python-wsgi-applications-using-uwsgi-web-server-with-nginx
# http://gunicorn-docs.readthedocs.org/en/latest/deploy.html
# https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-django-with-postgres-nginx-and-gunicorn
# https://www.digitalocean.com/community/tutorials/how-to-use-the-django-one-click-install-image **
# http://stackoverflow.com/questions/22841764/best-practice-for-django-project-working-directory-structure
# 
# cd "/home/$USER/sites/$1"

# mkdir -p ~/venvs
# cd ~/venvs
# virtualenv $1-env
# ln -s ~/venvs/$1-env/bin/activate /home/$USER/sites/$1/activate

# cd /home/$USER/sites/$1
# source activate
# pip install django
# django-admin.py startproject app

