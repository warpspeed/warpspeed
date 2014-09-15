#!/bin/bash

# Run via: cat init-server-clone.sh | ssh me@myserver /bin/bash

if [ $(id -u) != "0" ]; then
    echo "This script must be run as root." 1>&2
    exit 1
fi

HOSTNAME=$1
SSHKEY=$2
SSHPORT=$3
USERNAME=$4
PASSWORD=$5

# Install git.
aptitude -y install git-core

# Retrieve warpspeed repository.
git clone https://github.com/warpspeedio/warpseed-ubuntu-14.04.git ~/.warpspeed

# Make warspeed scripts executable.
cd ~/.warpspeed
chmod +x *.sh

# Begin server initialization.
./server-init.sh "$HOSTNAME" "$SSHKEY" "$SSHPORT" "$USERNAME" "$PASSWORD"

exit 0