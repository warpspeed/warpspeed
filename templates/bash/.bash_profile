# Warpspeed.io .bash_profile

# Add reference to warpspeed root dir.
export WS_SCRIPTS_ROOT="/home/{{user}}/.warpspeed"

# Add warpspeed bin directory to the path.
export PATH="$WS_SCRIPTS_ROOT/bin:$PATH"

# Include all warpspeed env files.
for f in ~/.ws_env_*; do source $f; done

# Include the .bashrc file.
[[ -r ~/.bashrc ]] && . ~/.bashrc
