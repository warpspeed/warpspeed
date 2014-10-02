# Warpspeed bash profile

# Add helpers directory to the path.
PATH="$HOME/warpspeed/helpers:$PATH"

# If the vagrant home directory exists, assume we are using vagrant.
if [ -d "/home/vagrant" ]; then
	LARAVEL_ENV="local"
fi

# Include the .bashrc file.
[[ -r ~/.bashrc ]] && . ~/.bashrc
