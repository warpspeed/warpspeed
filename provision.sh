#!/bin/bash

# Determine the directory this script is executing from.
WARPSPEED_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Include the warpspeed functions file.
source $WARPSPEED_ROOT/includes/installer-functions.sh

# Require that the root user be executing this script.
ws_require_root

# Declare array to track installers that should be run.
# Installers are added via command line args by passing --installer.
INSTALLERS=()

# Retrieve system ip address.
IPADDRESS=$(ws_get_ip_address)

# Process command line arguments and make sure the required args were passed.
for arg in "$@"; do
case $arg in
    -h=*|--hostname=*)
        HOSTNAME="${arg#*=}"
        shift
    ;;
    -k=*|--sshkey=*)
        SSHKEY="${arg#*=}"
        shift
    ;;
    -p=*|--password=*)
        PASSWORD="${arg#*=}"
        shift
    ;;
    -u=*|--user=*)
        WARPSPEED_USER="${arg#*=}"
        shift
    ;;
    --*)
        # Add arg to installers array.
        INSTALLERS+=("${arg:2}")
        shift
    ;;
esac; done

if [ -z "$HOSTNAME" ] || [ -z "$SSHKEY" ] || [ -z "$PASSWORD" ]; then
    echo "Usage: provision.sh [OPTION]..." 1>&2
    echo "Initializes a server and runs any installer scripts specified in the options." 1>&2
    echo "For complete information, visit: warpspeed.io" 1>&2
    echo -en "\n" 1>&2
    echo "Mandatory arguments:" 1>&2
    echo "  -h, --hostname=HOSTNAME         Hostname to be used for server." 1>&2
    echo "  -k, --sshkey=\"SSH PUBLIC KEY\"   Public key used for authentication to server." 1>&2
    echo "  -p, --password=PASSWORD         Password for the warpspeed user (and database admins)." 1>&2
    echo -en "\n" 1>&2
    echo "Optional arguments:" 1>&2
    echo "  --installer                     Installer script to run. Ex: --php will run the 'php.sh'" 1>&2
    echo "                                  installer script found in the installers directory." 1>&2
    echo "  -u, --user=username             Overrides default username (warpspeed)." 1>&2
    echo -en "\n" 1>&2
    exit 1
fi

# Username defaults to warpspeed if not overridden.
if [ -z "$WARPSPEED_USER" ]; then
    $WARPSPEED_USER="warpspeed"
fi

ws_log_header "Configuring hostname."
ws_set_hostname $HOSTNAME

ws_log_header "Configuring timezone."
ws_set_timezone UTC

ws_log_header "Running system updates."
ws_run_system_updates

ws_log_header "Configuring unattended upgrades."
ws_setup_automatic_updates

ws_log_header "Configuring firewall."
ws_setup_firewall

ws_log_header "Hardening SSH settings."
ws_setup_ssh_security

ws_log_header "Configuring fail2ban."
ws_setup_fail2ban

ws_log_header "Configuring warpspeed user."
ws_create_user $WARPSPEED_USER $PASSWORD sudo www-data

ws_log_header "Configuring ssh keys and known hosts."
ws_setup_ssh_keys $SSHKEY

ws_log_header "Configuring bash profile."
ws_setup_bash_profile

ws_log_header "Running specified installers."
ws_run_installers "${INSTALLERS[@]}"

ws_log_header "Restarting services."
ws_restart_flagged_services

echo "Server initialization complete."
echo "User: $WARPSPEED_USER was created with password: $PASSWORD"
echo "Please record this information and keep it in a safe place."
echo "To remotely access this server, use the following command:"
echo "ssh $WARPSPEED_USER@$IPADDRESS"
