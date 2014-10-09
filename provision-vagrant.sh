#!/bin/bash

# Determine the directory this script is executing from.
WARPSPEED_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set the warpspeed user.
WARPSPEED_USER="vagrant"

# Include the warpspeed functions file.
source $WARPSPEED_ROOT/includes/installer-functions.sh

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
# Set hostname and add to hosts file.
###############################################################################

ws_log_header "Configuring hostname."
echo $HOSTNAME > /etc/hostname
hostname -F /etc/hostname
sed -i "s/^127\.0\.1\.1.*/127\.0\.1\.1\t$HOSTNAME $HOSTNAME/" /etc/hosts

###############################################################################
# Set timezone.
###############################################################################

ws_log_header "Configuring timezone."
ln -s -f /usr/share/zoneinfo/UTC /etc/localtime

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
cp -f $WARPSPEED_ROOT/templates/bash/.bash_profile ~/.bash_profile
sed -i "s/{{user}}/$WARPSPEED_USER/g" ~/.bash_profile
cp -f ~/.bash_profile /home/$WARPSPEED_USER/.bash_profile
chown $WARPSPEED_USER:$WARPSPEED_USER /home/$WARPSPEED_USER/.bash_profile

# Generate a keypair for the new user and add common sites to the known hosts.
ssh-keygen -f /home/$WARPSPEED_USER/.ssh/id_rsa -t rsa -N ''
ssh-keyscan -H github.com >> /home/$WARPSPEED_USER/.ssh/known_hosts
ssh-keyscan -H bitbucket.org >> /home/$WARPSPEED_USER/.ssh/known_hosts

###############################################################################
# Run all installers that were passed as arguments.
###############################################################################

ws_log_header "Running specified installers."
for installer in "${INSTALLERS[@]}"; do
    INSTALLER_FULL_PATH="$WARPSPEED_ROOT/installers/$installer.sh"
    if [ -f "$INSTALLER_FULL_PATH" ]; then
        # Installer exists and is executable, run it.
        # Note: Installer scripts will have access to vars declared herein.
        source "$INSTALLER_FULL_PATH"
    fi
done

###############################################################################
# Restart services and show summary info.
###############################################################################

ws_restart_flagged_services
