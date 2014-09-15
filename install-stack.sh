#!/bin/bash

if [ $(id -u) != "0" ]; then
    echo "This script must be run as root." 1>&2
    exit 1
fi

SCRIPTS_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

###############################################################################
# Run installers.
###############################################################################

source $SCRIPTS_ROOT/installers/nginx.sh
source $SCRIPTS_ROOT/installers/php.sh
#./installers/nodejs.sh
#./installers/python.sh
#./installers/ruby.sh
#./installers/mongodb.sh
#./installers/mysql.sh
#./installers/postgres.sh
#./installers/beanstalkd.sh

###############################################################################
# Cleanup, restart services, and show init info.
###############################################################################

aptitude autoclean

# Restarts services that have a restart-service_name file in /tmp.
for service_name in $(ls /tmp/ | grep restart-* | cut -d- -f2-10); do
    service $service_name restart
    rm -f /tmp/restart-$service_name
done
