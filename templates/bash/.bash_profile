# Warpspeed.io .bash_profile

# Add reference to warpspeed root dir (used by helpers).
export WS_SCRIPTS_ROOT="/home/warpspeed/warpspeed"

# Add helpers directory to the path.
export PATH="$WS_SCRIPTS_ROOT/helpers:$PATH"

# Include all warpspeed env files.
for f in ~/.ws_env_*; do source $f; done

# Include the .bashrc file.
[[ -r ~/.bashrc ]] && . ~/.bashrc
