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

ws_log_header "Installing go."

# Name of the go binaries to download.
FILENAME=go1.20.2.linux-amd64.tar.gz

# Download go binaries.
wget -nv https://dl.google.com/go/$FILENAME

# Extract files, set permissions, and move to proper location.
tar -C /usr/local -xzf $FILENAME

# Setup go environment.
BASHRC=/home/$WARPSPEED_USER/.bashrc
echo '# Go configuration.' >> $BASHRC
echo 'export GOROOT=/usr/local/go' >> $BASHRC
echo 'export GOPATH=$WARPSPEED_ROOT/sites' >> $BASHRC
echo 'export PATH=$GOPATH/bin:$GOROOT/bin:$PATH' >> $BASHRC
echo -en "\n" >> $BASHRC

# Clean up.
rm $FILENAME
