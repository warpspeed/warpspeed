#!/bin/bash

# Default set of installers to run.
DEFAULT_INSTALLERS="--nginx --php --mysql --postgres"

# Read input from user.
echo "System hostname (default: $HOSTNAME):"
read SYSTEM_HOSTNAME

echo "WarpSpeed repository to pull from (default: warpspeed/warpspeed):"
read REPOPATH

echo "WarpSpeed user (default: warpspeed):"
read USERNAME

echo "WarpSpeed user password (for sudo):"
read PASSWORD

echo "SSH public key for authentication (password access will be disabled):"
read SSHKEY

echo "Installers options (default: $DEFAULT_INSTALLERS):"
read INSTALLERS

# Process inputs, defaults, and required params.
if [ -z "$SYSTEM_HOSTNAME" ]; then
    SYSTEM_HOSTNAME=$HOSTNAME
fi

if [ -z "$REPOPATH" ]; then
    REPOPATH="warpspeed/warpspeed"
fi

if [ -z "$USERNAME" ]; then
    USERNAME="warpspeed"
fi

if [ -z "$PASSWORD" ]; then
    echo "Error: WarpSpeed user password is required."
    exit 1
fi

if [ -z "$SSHKEY" ]; then
    echo "Error: WarpSpeed user SSH public key is required."
    exit 1
fi

if [ -z "$INSTALLERS" ]; then
    INSTALLERS=$DEFAULT_INSTALLERS
fi

# Ensure git is installed.
apt-get -y install git-core

# Clone warpspeed repository if it is not present.
if [ ! -d /home/$USERNAME/.warpspeed ]; then
    mkdir -p /home/$USERNAME
    git clone https://github.com/$REPOPATH.git /home/$USERNAME/.warpspeed
fi

# Run the provisioning script and pass along any desired installer params.
source /home/$USERNAME/.warpspeed/provision.sh -h="$SYSTEM_HOSTNAME" -u="$USERNAME" -p="$PASSWORD" -k="$SSHKEY" $INSTALLERS
