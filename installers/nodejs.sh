#!/bin/bash

if [ $(id -u) != "0" ]; then
    echo "This script must be run as root." 1>&2
    exit 1
fi

apt-get -y install python-software-properties
add-apt-repository -y ppa:chris-lea/node.js
apt-get update

apt-get -y install nodejs

exit 0