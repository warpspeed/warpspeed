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
apt-get -y install unattended-upgrades

# Configure auto update intervals and allowed origins.
cp templates/apt/10periodic /etc/apt/apt.conf.d/10periodic
cp templates/apt/50unattended-upgrades/etc/apt/apt.conf.d/50unattended-upgrades

ws_log_header "Configuring firewall."
sudo apt-get -y install ufw

# Set default rules: deny all incoming traffic, allow all outgoing traffic.
ufw default deny incoming
ufw default allow outgoing
ufw logging on

# Only allow ssh, http, and https.
ufw allow ssh
ufw allow http
ufw allow https

# Enable firewall.
echo y|ufw enable

ws_log_header "Hardening SSH settings."
sed -i "s/LoginGraceTime 120/LoginGraceTime 30/" /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config
ws_flag_service ssh

ws_log_header "Configuring fail2ban."
apt-get -y install fail2ban
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sed -ri "/^\[ssh-ddos\]$/,/^\[/s/enabled[[:blank:]]*=.*/enabled = true/" /etc/fail2ban/jail.local
ws_flag_service fail2ban

ws_log_header "Configuring warpspeed user."

# Add the user and specify the shell.
useradd -m -s /bin/bash $WARPSPEED_USER

# Set the user password.
echo "$WARPSPEED_USER:$PASSWORD" | chpasswd

# Add the user to the sudo and www-data groups.
adduser $WARPSPEED_USER sudo
adduser $WARPSPEED_USER www-data

# Ensure .ssh dir exists.
mkdir -p ~/.ssh

# Add the warpspeed ssh key, overwriting any existing keys.
echo "# WARPSPEED" > ~/.ssh/authorized_keys
echo "$SSHKEY" >> ~/.ssh/authorized_keys

# Add the .ssh dir for the new user and copy over the authorized keys.
mkdir -p /home/warpspeed/.ssh
cp ~/.ssh/authorized_keys /home/$WARPSPEED_USER/.ssh/authorized_keys

ws_log_header "Configuring ssh keys and known hosts."
ws_setup_ssh_keys

# Update directory permissions for the new user.
chown -R $WARPSPEED_USER:$WARPSPEED_USER /home/$WARPSPEED_USER
chmod -R 755 /home/$WARPSPEED_USER
chmod 0700 /home/$WARPSPEED_USER/.ssh
chmod 0600 /home/$WARPSPEED_USER/.ssh/authorized_keys

ws_log_header "Configuring bash profile."
ws_setup_bash_profile

ws_log_header "Running specified installers."
ws_run_installers "$INSTALLERS"

ws_log_header "Restarting services."
ws_restart_flagged_services

echo "Server initialization complete."
echo "User: $WARPSPEED_USER was created with password: $PASSWORD"
echo "Please record this information and keep it in a safe place."
echo "To remotely access this server, use the following command:"
echo "ssh $WARPSPEED_USER@$IPADDRESS"
