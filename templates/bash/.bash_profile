# Warpspeed.io .bash_profile

# Specify the warpspeed user.
export WARPSPEED_USER="{{user}}"

# Specify the warpspeed root directory.
export WARPSPEED_ROOT="/home/$WARPSPEED_USER/.warpspeed"

# Add warpspeed bin directory to the path.
export PATH="$WARPSPEED_ROOT/bin:$PATH"

# Include all warpspeed env files.
if [ -f ~/.ws_env_* ]; then
    for f in ~/.ws_env_*; do source $f; done
fi

# Include the .bashrc file.
[[ -r ~/.bashrc ]] && . ~/.bashrc
