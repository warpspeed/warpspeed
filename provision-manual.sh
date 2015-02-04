#!/bin/bash

# Visit http://warpspeed.io for complete information.
# (c) Turner Logic, LLC. Distributed under the GNU GPL v2.0.

# Default set of installers to run.
DEFAULT_INSTALLERS="--nginx --php --python --rbenv --beanstalkd --mysql --postgresql --mongodb"

# Read input from user.
echo "WarpSpeed user password (for sudo):"
read PASSWORD

echo "SSH public key for authentication (password access will be disabled):"
read SSHKEY

echo "Installers options (default: $DEFAULT_INSTALLERS):"
read INSTALLERS

# Setup defaults and process params.
REPOPATH="warpspeed/warpspeed"
USERNAME="warpspeed"

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

# Run update to make sure git-core will be available.
apt-get update

# Ensure git is installed.
apt-get -y install git-core

# Clone warpspeed repository if it is not present.
if [ ! -d /home/$USERNAME/.warpspeed ]; then
    mkdir -p /home/$USERNAME
    git clone --branch warpspeed-v1 --depth=1 https://github.com/$REPOPATH.git /home/$USERNAME/.warpspeed
fi

# Run the provisioning script and pass along any desired installer params.
source /home/$USERNAME/.warpspeed/provision.sh -h="$HOSTNAME" -u="$USERNAME" -p="$PASSWORD" -k="$SSHKEY" $INSTALLERS
