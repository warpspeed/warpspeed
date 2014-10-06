#!/bin/bash

# This script is for manual provisioning without warpspeed.io.
# You must provide values for these variables.
HOSTNAME=""
PASSWORD=""
SSHKEY=""

# Setup github repo to pull from.
REPOPATH="warpspeedio/warpspeed"

# Ensure git is installed.
apt-get -y install git-core

# Clone warpspeed repository if it is not present.
if [ ! -d /home/warpspeed/.warpspeed ]; then
    mkdir -p /home/warpspeed
    git clone https://github.com/$REPOPATH.git /home/warpspeed/.warpspeed
    chown -R warpspeed:warpspeed /home/warpspeed/.warpspeed
fi

# Run the provisioning script and pass along any desired installer params.
source /home/warpspeed/.warpspeed/provision.sh --h=$HOSTNAME --p="$PASSWORD" --k="$SSHKEY" --nginx --php
