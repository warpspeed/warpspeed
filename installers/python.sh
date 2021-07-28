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

ws_log_header "Installing python."

# Install python and associated tools.
apt -y install python3-dev python3-pip python3-virtualenv virtualenvwrapper
