# Warpspeed bash profile

# Add helpers directory to the path.
export PATH="$HOME/warpspeed/helpers:$PATH"

# Add rbenv to the path.
export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/plugins/ruby-build/bin:$PATH"

# Initialize rbenv.
eval "$(rbenv init -)"

# If the vagrant home directory exists, assume we are using vagrant.
if [ -d "/home/vagrant" ]; then
	SYSTEM_ENV="local"
fi

# Include the .bashrc file.
[[ -r ~/.bashrc ]] && . ~/.bashrc
