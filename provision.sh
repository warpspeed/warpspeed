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

###############################################################################
# Process command line arguments and make sure the required args were passed.
###############################################################################

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
if [ -z "$HOSTNAME" ]; then
    $WARPSPEED_USER="warpspeed"
fi

###############################################################################
# Set hostname and add to hosts file.
###############################################################################

ws_log_header "Configuring hostname."
echo $HOSTNAME > /etc/hostname
hostname -F /etc/hostname
sed -i "s/^127\.0\.1\.1.*/127\.0\.1\.1\t$HOSTNAME $HOSTNAME/" /etc/hosts

###############################################################################
# Set timezone.
###############################################################################

ws_log_header "Configuring timezone."
ln -s -f /usr/share/zoneinfo/UTC /etc/localtime

###############################################################################
# Run system updates and install prerequisites.
###############################################################################

ws_log_header "Running system updates."
apt-get update
apt-get -y upgrade
apt-get -y install python-software-properties build-essential git-core

###############################################################################
# Install and configure unattended upgrades for security packages.
###############################################################################

ws_log_header "Configuring unattended upgrades."
apt-get -y install unattended-upgrades

# Configure auto update intervals and allowed origins.
cp templates/apt/10periodic /etc/apt/apt.conf.d/10periodic
cp templates/apt/50unattended-upgrades/etc/apt/apt.conf.d/50unattended-upgrades

###############################################################################
# Install and configure firewall.
###############################################################################

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

###############################################################################
# Harden ssh settings.
###############################################################################

ws_log_header "Hardening SSH settings."
sed -i "s/LoginGraceTime 120/LoginGraceTime 30/" /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config
ws_flag_service ssh

###############################################################################
# Install fail2ban and configure to protect ssh.
###############################################################################

ws_log_header "Configuring fail2ban."
apt-get -y install fail2ban
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sed -ri "/^\[ssh-ddos\]$/,/^\[/s/enabled[[:blank:]]*=.*/enabled = true/" /etc/fail2ban/jail.local
ws_flag_service fail2ban

###############################################################################
# Configure the warpspeed user.
###############################################################################

ws_log_header "Configuring warpspeed user."

# Add the user and specify the shell.
useradd -m -s /bin/bash $WARPSPEED_USER

# Set the user password.
echo "$WARPSPEED_USER:$PASSWORD" | chpasswd

# Add the user to the sudo group.
adduser $WARPSPEED_USER sudo

# Ensure .ssh dir exists.
mkdir -p ~/.ssh

# Add the warpspeed ssh key, overwriting any existing keys.
echo "# WARPSPEED" > ~/.ssh/authorized_keys
echo "$SSHKEY" >> ~/.ssh/authorized_keys

# Add the .ssh dir for the new user and copy over the authorized keys.
mkdir -p /home/warpspeed/.ssh
cp ~/.ssh/authorized_keys /home/$WARPSPEED_USER/.ssh/authorized_keys

# Generate a keypair for the new user and add common sites to the known hosts.
ssh-keygen -f /home/$WARPSPEED_USER/.ssh/id_rsa -t rsa -N ''
ssh-keyscan -H github.com >> /home/$WARPSPEED_USER/.ssh/known_hosts
ssh-keyscan -H bitbucket.org >> /home/$WARPSPEED_USER/.ssh/known_hosts

# Update directory permissions for the new user.
chown -R $WARPSPEED_USER:$WARPSPEED_USER /home/$WARPSPEED_USER
chmod -R 755 /home/$WARPSPEED_USER
chmod 0700 /home/$WARPSPEED_USER/.ssh
chmod 0600 /home/$WARPSPEED_USER/.ssh/authorized_keys

###############################################################################
# Setup bash profile.
###############################################################################

ws_log_header "Configuring bash profile."
cp -f $WARPSPEED_ROOT/templates/bash/.bash_profile ~/.bash_profile
sed -i "s/{{user}}/$WARPSPEED_USER/g" ~/.bash_profile
cp -f ~/.bash_profile /home/$WARPSPEED_USER/.bash_profile
chown $WARPSPEED_USER:$WARPSPEED_USER /home/$WARPSPEED_USER/.bash_profile

###############################################################################
# Run all installers that were passed as arguments.
###############################################################################

ws_log_header "Running specified installers."
for installer in "${INSTALLERS[@]}"; do
    INSTALLER_FULL_PATH="$WARPSPEED_ROOT/installers/$installer.sh"
    if [ -f "$INSTALLER_FULL_PATH" ]; then
        # Installer exists and is executable, run it.
        # Note: Installer scripts will have access to vars declared herein.
        source "$INSTALLER_FULL_PATH"
    fi
done

###############################################################################
# Restart services and show summary info.
###############################################################################

ws_restart_flagged_services

echo "Server initialization complete."
echo "User: $WARPSPEED_USER was created with password: $PASSWORD"
echo "Please record this information and keep it in a safe place."
echo "To remotely access this server, use the following command:"
echo "ssh $WARPSPEED_USER@$IPADDRESS"
