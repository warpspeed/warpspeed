#!/bin/bash

# Determine the directory this script is executing from.
WARPSPEED_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set the warpspeed user.
WARPSPEED_USER="vagrant"

# Include the warpspeed functions file.
source $WARPSPEED_ROOT/includes/installer-functions.sh

# Require that the root user be executing this script.
ws_require_root

# Declare array to track installers that should be run.
# Installers are added via command line args by passing --installer.
INSTALLERS=()

# Any script that requires a password (such as database installers) will use this.
PASSWORD=warpspeed

# Process command line arguments.
for arg in "$@"; do
case $arg in
    -h=*|--hostname=*)
        HOSTNAME="${arg#*=}"
        shift
    ;;
    --*)
        # Add arg to installers array.
        INSTALLERS+=("${arg:2}")
        shift
    ;;
esac; done

if [ -z "$HOSTNAME" ]; then
    echo "Usage: warpspeed-vagrant.sh [OPTION]..." 1>&2
    echo "Initializes a vagrant server and runs any installer scripts specified in the options." 1>&2
    echo "For complete information, visit: warpspeed.io" 1>&2
    echo -en "\n" 1>&2
    echo "Mandatory arguments:" 1>&2
    echo "  -h, --hostname=HOSTNAME         Hostname to be used for server." 1>&2
    echo -en "\n" 1>&2
    echo "Optional arguments:" 1>&2
    echo "  --installer                     Installer script to run. Ex: --php will run the 'php.sh'" 1>&2
    echo "                                  installer script found in the installers directory." 1>&2
    echo -en "\n" 1>&2
    exit 1
fi

ws_log_header "Configuring hostname."
ws_set_hostname $HOSTNAME

ws_log_header "Configuring timezone."
ws_set_timezone UTC

ws_log_header "Running system updates."
ws_run_system_updates

ws_log_header "Configuring bash profile."
ws_setup_bash_profile

ws_log_header "Configuring ssh keys and known hosts."
ws_setup_ssh_keys

ws_log_header "Running specified installers."
ws_run_installers "$INSTALLERS"

ws_log_header "Restarting services."
ws_restart_flagged_services
