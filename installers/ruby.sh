#!/bin/bash

# Make sure warpspeed environment vars are available before proceeding.
if [ -z "$WARPSPEED_ROOT" ] || [ -z "$WARPSPEED_USER" ]; then
    echo "Error: It appears that this server was not provisioned with Warpspeed."
    echo "WARPSPEED_ROOT and WARPSPEED_USER env vars were not found."
    exit 1
fi

# Import the warpspeed functions.
source $WARPSPEED_ROOT/includes/functions.sh

# Require that the root user be executing this script.
ws_require_root

apt-get -y install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties

cd /usr/local
git clone git://github.com/sstephenson/rbenv.git rbenv
git clone git://github.com/sstephenson/ruby-build.git rbenv/plugins/ruby-build

chown -R $WARPSPEED_USER:$WARPSPEED_USER rbenv

# todo
# cat > /home/$USER/.ws_env_ruby << EOF
# # Add rbenv and ruby-build to the path.
# export PATH="/usr/local/rbenv/bin:/usr/local/rbenv/plugins/ruby-build/bin:$PATH"

# # Initialize rbenv.
# eval "$(rbenv init -)"

# EOF

# chown $USER:$USER /home/$USER/.ws_env_ruby
