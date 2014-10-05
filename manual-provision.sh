#!/bin/bash

# This script is for manual provisioning without warpspeed.io.
# You must provide values for these variables.
HOSTNAME=""
PASSWORD=""
SSHKEY=""

# Setup github repo to pull from.
REPOPATH="turnerlogic/warpspeed-scripts"

# Ensure git is installed.
apt-get -y install git-core

# Clone warpspeed repository if it is not present.
if [ ! -d ~/warpspeed ]; then
  	git clone https://github.com/$REPOPATH.git ~/warpspeed
fi

# Run the initialization script and pass along any desired installer params.
source ~/warpspeed/warpspeed.sh --h=$HOSTNAME --p="$PASSWORD" --k="$SSHKEY" --nginx --php

# When finished, move the scripts to the warpspeed user's home directory and update permissions.
mv -f ~/warpspeed /home/warpspeed/warpspeed
chown -R warpspeed:warpspeed /home/warpspeed/warpspeed
