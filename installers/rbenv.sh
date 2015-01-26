#!/bin/bash

# Make sure warpspeed environment vars are available before proceeding.
if [ -z "$WARPSPEED_ROOT" ] || [ -z "$WARPSPEED_USER" ]; then
    echo "Error: It appears that this server was not provisioned with Warpspeed."
    echo "WARPSPEED_ROOT and WARPSPEED_USER env vars were not found."
    exit 1
fi

# Import the warpspeed functions.
source $WARPSPEED_ROOT/includes/installer-functions.sh

# Require that the root user be executing this script.
ws_require_root

ws_log_header "Installing rbenv."

# Make sure git is installed.
apt-get -y install git-core

# Clone the rbenv and ruby-build repos.
git clone git://github.com/sstephenson/rbenv.git /home/$WARPSPEED_USER/.rbenv
git clone https://github.com/sstephenson/ruby-build.git /home/$WARPSPEED_USER/.rbenv/plugins/ruby-build

# Setup environment.
echo 'export PATH="/home/$WARPSPEED_USER/.rbenv/bin:$PATH"' >> /home/$WARPSPEED_USER/.bash_profile
echo 'eval "$(rbenv init -)"' >> /home/$WARPSPEED_USER/.bash_profile

# Ensure proper permissions.
chown -R $WARPSPEED_USER:$WARPSPEED_USER /home/$WARPSPEED_USER/.rbenv
chown $WARPSPEED_USER:$WARPSPEED_USER /home/$WARPSPEED_USER/.bash_profile
