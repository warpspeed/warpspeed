#!/bin/bash

# Determine the directory this script is executing from.
WS_SCRIPTS_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Include the warpspeed functions file.
source $WS_SCRIPTS_ROOT/ws-functions.sh

# Require that the root user be executing this script.
ws_require_root

# Declare array to track installers that should be run.
# Installers are added via command line args by passing --installer.
INSTALLERS=()

# Retrieve system ip address.
IPADDRESS=$(ws_get_ip_address)

# Any script that requires a password (such as database installers) will use this.
PASSWORD=warpspeed

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

ws_log_header "Configuring timezone."
ln -s -f "/usr/share/zoneinfo/$1" /etc/localtime

###############################################################################
# Set timezone to UTC
###############################################################################

ws_log_header "Configuring hostname."
echo $1 > /etc/hostname
hostname -F /etc/hostname
sed -i "s/^127\.0\.1\.1.*/127\.0\.1\.1\t$1 $1/" /etc/hosts

###############################################################################
# Run system updates and install prerequisites.
###############################################################################

ws_log_header "Running system updates."
apt-get update
apt-get -y upgrade
apt-get -y install python-software-properties build-essential git-core

###############################################################################
# Setup bash profile.
###############################################################################

ws_log_header "Configuring bash profile."
cp -f $WS_SCRIPTS_ROOT/templates/bash/.bash_profile /home/vagrant/.bash_profile
chown vagrant:vagrant /home/vagrant/.bash_profile

###############################################################################
# Run all installers that were passed as arguments.
###############################################################################

ws_log_header "Running specified installers."
for installer in "${INSTALLERS[@]}"; do
	INSTALLER_FULL_PATH="$SCRIPTS_ROOT/installers/$installer.sh"
	if [ -x "$INSTALLER_FULL_PATH" ]; then
		# Installer exists and is executable, run it.
		# Note: Installer scripts will have access to vars declared herein.
		source "$INSTALLER_FULL_PATH"
	fi
done

###############################################################################
# Restart services and show summary info.
###############################################################################

ws_restart_flagged_services
