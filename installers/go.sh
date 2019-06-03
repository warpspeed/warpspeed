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

ws_log_header "Installing golang."

wget https://dl.google.com/go/go1.12.5.linux-amd64.tar.gz

sudo tar -xvf go1.12.5.linux-amd64.tar.gz
sudo mv go /usr/local

export GOROOT=/usr/local/go

export GOPATH=$HOME/sites
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

echo 'export GOPATH=$HOME/sites' >> ~/.profile
echo 'PATH=$GOPATH/bin:$GOROOT/bin:$PATH' >> ~/.profile