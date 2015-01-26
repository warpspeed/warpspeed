# Warpspeed.io .bash_profile

# Specify the warpspeed user.
export WARPSPEED_USER="{{user}}"

# Specify the warpspeed root directory.
export WARPSPEED_ROOT="/home/$WARPSPEED_USER/.warpspeed"

# Add warpspeed bin directory to the path.
export PATH="$WARPSPEED_ROOT/bin:$PATH"

# Include the .bashrc file.
[[ -r ~/.bashrc ]] && . ~/.bashrc
