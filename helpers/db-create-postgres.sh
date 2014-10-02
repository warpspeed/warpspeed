#!/bin/bash

EXPECTED_ARGS=3
E_BADARGS=65
 
if [ $# -ne $EXPECTED_ARGS ]
then
  echo "Usage: $0 dbname dbuser dbpass"
  exit $E_BADARGS
fi

# Create the new user.
echo "CREATE ROLE $2 WITH LOGIN ENCRYPTED PASSWORD '$3';" | sudo -i -u postgres psql

# Create the database and set the owner to the newly created user.
sudo -i -u postgres createdb --owner=$2 $1

echo "Database: $1 was created successfully and is owned by user: $2 with password: $3"
