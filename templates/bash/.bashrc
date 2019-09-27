# WarpSpeed.io .bashrc

# This file gets loaded during non-interactive logins, like when you perform a git push deployment.
# It also automatically gets loaded during interactive logins because it is called via the .bash_profile.

# Any environment settings or non-visual customizations should be added to this file.
# Please do not modify any of the WarpSpeed environment settings or things will not work as expected.

# Specify the WarpSpeed user.
export WARPSPEED_USER="{{user}}"

# Specify the WarpSpeed root directory.
export WARPSPEED_ROOT="/home/$WARPSPEED_USER/.warpspeed"

# Add WarpSpeed bin directory to the path.
export PATH="$WARPSPEED_ROOT/bin:$PATH"

