#!/bin/bash

USER=warpspeed

# If the vagrant home directory exists, assume we are using vagrant.
if [ -d "/home/vagrant" ]; then
	USER=vagrant
fi

BACKUPDIR="/home/$USER/sites/db-backups"

# Create the db backup directory if it doesn't exist.
if [ ! -d $BACKUPDIR ]; then
  mkdir -p $BACKUPDIR
  echo "Created the db backup directory."
fi

echo "Please enter your mysql root database password when prompted."

if [ -z "$1" ]; then
	FILENAME="$BACKUPDIR/all_dbs_$(date +%Y-%m-%d_%H%M%S).sql.gz"
	mysqldump -u root -p --add-drop-table --all-databases | gzip -9 > $FILENAME
else
	FILENAME="$BACKUPDIR/$1_$(date +%Y-%m-%d_%H%M%S).sql.gz"
	mysqldump -u root -p --add-drop-table $1 | gzip -9 > $FILENAME
fi

echo "Backup saved to: $FILENAME"
