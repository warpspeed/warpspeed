#!/bin/bash

EXPECTED_ARGS=3
E_BADARGS=65
 
Q1="CREATE DATABASE IF NOT EXISTS $1;"
Q2="GRANT ALL ON $1.* TO '$2'@'localhost' IDENTIFIED BY '$3';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"
 
if [ $# -ne $EXPECTED_ARGS ]
then
  echo "Usage: $0 dbname dbuser dbpass"
  exit $E_BADARGS
fi

echo "Please enter your mysql root database password when prompted."
 
mysql -uroot -p -e "$SQL"

if [ $? -eq 0 ]; then
    echo "Database: '$1' was created successfully and is accessible by user: '$2' with password: '$3'."
fi
