#!/bin/bash

if [ $(id -u) != "0" ]; then
    echo "This script must be run as root." 1>&2
    exit 1
fi

apt-get -y install beanstalkd

sed -i "s/#START=yes/START=yes/g" /etc/default/beanstalkd

touch /tmp/restart-beanstalkd

exit 0