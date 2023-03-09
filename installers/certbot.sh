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

ws_log_header "Installing certbot."

# Obtain password from environment or parameter.
if [ -z "$CERTBOT_EMAIL" ]; then
    if [ -z "$1" ]; then
        # Certbot email must be set or passed in, warn and exit.
        echo "Usage: $0 certbot-email-address"
        exit 1
    else
        CERTBOT_EMAIL="$1"
    fi
fi

# Store certbot email.
BASHRC=/home/$WARPSPEED_USER/.bashrc
echo '# Certbot configuration.' >> $BASHRC
echo 'export CERTBOT_EMAIL=$CERTBOT_EMAIL' >> $BASHRC
echo -en "\n" >> $BASHRC

snap install core
snap refresh core

snap install --classic certbot
