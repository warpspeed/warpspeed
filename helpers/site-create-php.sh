#!/bin/bash

user=`whoami`

if [ -z "$1" ]; then
  echo "Usage: site-create <hostname> (no www)"
  exit 1
fi

# make sure the site doesn't already exist
if [ -d "/home/$user/sites/$1" ]; then
  echo "Error: The site /home/$user/sites/$1 already exists."
  exit 1
fi

echo "Creating site..."

mkdir -p "/home/$user/sites/$1"

cp ./templates/nginx/site-php.conf /etc/nginx/sites-available/$1
sudo ln -s /etc/nginx/sites-available/$1 /etc/nginx/sites-enabled/$1

cp ./templates/php/www.conf /etc/php5/fpm/pool.d/www.conf
sed -i "s/{{ domain }}/$1/g" /etc/php5/fpm/pool.d/www.conf

mkdir -p "/home/$user/repos/$1.git"
cd "/home/$user/repos/$1.git"
git init --bare
chown -R $user:$user "/home/$user/sites/$1"
cp ./templates/git/post-receive /home/$user/repos/$1.git/hooks/post-receive
sudo chmod +x "/home/$user/repos/$1.git/hooks/post-receive"

echo "Use: git remote add web ssh://$user@$1/home/$user/repos/$1.git"
echo "and: git push web +master:refs/heads/master"

# restart services
sudo service nginx reload
sudo service php5-fpm restart
sudo service monit restart

echo "Site setup is complete."