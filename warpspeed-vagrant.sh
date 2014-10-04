#!/bin/bash

if [ $(id -u) != "0" ]; then
    echo "This script must be run as root." 1>&2
    exit 1
fi

# Declare array to track installers that should be run.
# Installers are added via command line args by passing --installer.
INSTALLERS=()

# Retrieve system ip address.
IPADDRESS=$(ifconfig eth0 | awk -F: '/inet addr:/ {print $2}' | awk '{ print $1 }')

# Determine the directory this script is executing from.
SCRIPTS_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

###############################################################################
# Process command line arguments.
###############################################################################

for arg in "$@"; do
case $arg in
	-h=*|--hostname=*)
        HOSTNAME="${arg#*=}"
        shift
    ;;
    --*)
        # Add arg to installers array.
        INSTALLERS+=("${arg:2}")
        shift
    ;;
esac; done

if [ -z "$HOSTNAME" ]; then
  echo "Usage: warpspeed-vagrant.sh [OPTION]..." 1>&2
  echo "Initializes a vagrant server and runs any installer scripts specified in the options." 1>&2
  echo "For complete information, visit: warpspeed.io" 1>&2
  echo -en "\n" 1>&2
  echo "Mandatory arguments:" 1>&2
  echo "  -h, --hostname=HOSTNAME         Hostname to be used for server." 1>&2
  echo -en "\n" 1>&2
  echo "Optional arguments:" 1>&2
  echo "  --installer                     Installer script to run. Ex: --php will run the 'php.sh'" 1>&2
  echo "                                  installer script found in the installers directory." 1>&2
  echo -en "\n" 1>&2
  exit 1
fi

###############################################################################
# Update system hostname and add to hosts file.
###############################################################################

echo $HOSTNAME > /etc/hostname
hostname -F /etc/hostname
sed -i "s/^127\.0\.1\.1.*/127\.0\.1\.1\t$HOSTNAME $HOSTNAME/" /etc/hosts

###############################################################################
# Set timezone to UTC
###############################################################################

ln -s -f /usr/share/zoneinfo/UTC /etc/localtime

###############################################################################
# Run system updates and install prerequisites.
###############################################################################

apt-get update
apt-get -y upgrade
apt-get -y install python-software-properties build-essential git-core

###############################################################################
# Setup bash profile.
###############################################################################

cp -f $SCRIPTS_ROOT/templates/bash/.bash_profile /home/vagrant/.bash_profile
chown vagrant:vagrant /home/vagrant/.bash_profile

###############################################################################
# Run all installers that were passed as arguments.
###############################################################################

for installer in "${INSTALLERS[@]}"; do
	INSTALLER_FULL_PATH="$SCRIPTS_ROOT/installers/$installer.sh"
	echo $INSTALLER_FULL_PATH
	if [ -x "$INSTALLER_FULL_PATH" ]; then
		# Installer exists and is executable, run it.
		# Note: Installer scripts will have access to vars declared herein.
		source "$INSTALLER_FULL_PATH"
	fi
done

###############################################################################
# Clean up and restart services.
###############################################################################

# Restarts services that have a restart-service_name file in /tmp.
for service_name in $(ls /tmp/ | grep restart-* | cut -d- -f2-10); do
    service $service_name restart
    rm -f /tmp/restart-$service_name
done
