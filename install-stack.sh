#!/bin/bash

if [ $(id -u) != "0" ]; then
    echo "This script must be run as root." 1>&2
    exit 1
fi

SCRIPTS_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

###############################################################################
# Run installers.
###############################################################################

# Copy bash profile to proper location.
cp $SCRIPTS_ROOT/templates/bash/.bash_profile $SCRIPTS_ROOT/../.bash_profile

source $SCRIPTS_ROOT/installers/php.sh
source $SCRIPTS_ROOT/installers/ruby.sh
source $SCRIPTS_ROOT/installers/python.sh
source $SCRIPTS_ROOT/installers/nginx-passenger.sh
source $SCRIPTS_ROOT/installers/mysql.sh root
source $SCRIPTS_ROOT/installers/postgres.sh

###############################################################################
# Cleanup, restart services, and show init info.
###############################################################################

aptitude autoclean

# Restarts services that have a restart-service_name file in /tmp.
for service_name in $(ls /tmp/ | grep restart-* | cut -d- -f2-10); do
    service $service_name restart
    rm -f /tmp/restart-$service_name
done
