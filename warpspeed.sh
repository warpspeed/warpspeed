#!/bin/bash

# Determine the directory this script is executing from.
WS_SCRIPTS_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Include the warpspeed functions file.
source $WS_SCRIPTS_ROOT/ws-functions.sh

# Require that the root user be executing this script.
ws_require_root

# Declare array to track installers that should be run.
# Installers are added via command line args by passing --installer.
INSTALLERS=()

# Retrieve system ip address.
IPADDRESS=$(ws_get_ip_address)

###############################################################################
# Process command line arguments and make sure required args were provided.
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
    --*)
        # Add arg to installers array.
        INSTALLERS+=("${arg:2}")
        shift
    ;;
esac; done

if [ -z "$HOSTNAME" ] || [ -z "$SSHKEY" ] || [ -z "$PASSWORD" ]; then
  echo "Usage: warpspeed.sh [OPTION]..." 1>&2
  echo "Initializes a server and runs any installer scripts specified in the options." 1>&2
  echo "For complete information, visit: warpspeed.io" 1>&2
  echo -en "\n" 1>&2
  echo "Mandatory arguments:" 1>&2
  echo "  -h, --hostname=HOSTNAME         Hostname to be used for server." 1>&2
  echo "  -k, --sshkey='SSH PUBLIC KEY'   Public key used for authentication to server." 1>&2
  echo "  -p, --password=PASSWORD         Password for the warpspeed user (and database admins)." 1>&2
  echo -en "\n" 1>&2
  echo "Optional arguments:" 1>&2
  echo "  --installer                     Installer script to run. Ex: --php will run the 'php.sh'" 1>&2
  echo "                                  installer script found in the installers directory." 1>&2
  echo -en "\n" 1>&2
  exit 1
fi

###############################################################################
# Update system hostname and add to hosts file.
###############################################################################

ws_log_header "Configuring timezone."
ln -s -f /usr/share/zoneinfo/UTC /etc/localtime

###############################################################################
# Set timezone to UTC
###############################################################################

ws_log_header "Configuring hostname."
echo $HOSTNAME > /etc/hostname
hostname -F /etc/hostname
sed -i "s/^127\.0\.1\.1.*/127\.0\.1\.1\t$HOSTNAME $HOSTNAME/" /etc/hosts

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
# Add warpspeed user, set password, and enable sudo.
###############################################################################

ws_log_header "Adding warpspeed user."
useradd -m -s /bin/bash warpspeed
echo "warpspeed:$PASSWORD" | chpasswd
adduser warpspeed sudo

###############################################################################
# Add ssh key for warpspeed user.
###############################################################################

ws_log_header "Adding ssh key."

mkdir -p ~/.ssh
echo "# WARPSPEED USER" >> ~/.ssh/authorized_keys
echo "$SSHKEY" >> ~/.ssh/authorized_keys

mkdir -p /home/warpspeed/.ssh
cp ~/.ssh/authorized_keys /home/warpspeed/.ssh/authorized_keys

ssh-keygen -f /home/warpspeed/.ssh/id_rsa -t rsa -N ''
ssh-keyscan -H github.com >> /home/warpspeed/.ssh/known_hosts
ssh-keyscan -H bitbucket.org >> /home/warpspeed/.ssh/known_hosts

chown -R warpspeed:warpspeed /home/warpspeed
chmod -R 755 /home/warpspeed
chmod 700 /home/warpspeed/.ssh/id_rsa

# Update ssh key permissions.
#chmod 0700 /home/warpspeed/.ssh
#chmod 0600 /home/warpspeed/.ssh/authorized_keys

###############################################################################
# Setup bash profile.
###############################################################################

ws_log_header "Configuring bash profile."
cp -f $WS_SCRIPTS_ROOT/templates/bash/.bash_profile /home/warpspeed/.bash_profile
chown warpspeed:warpspeed /home/warpspeed/.bash_profile

###############################################################################
# Run all installers that were passed as arguments.
###############################################################################

ws_log_header "Running specified installers."
for installer in "${INSTALLERS[@]}"; do
	INSTALLER_FULL_PATH="$WS_SCRIPTS_ROOT/installers/$installer.sh"
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
echo "User: warpspeed was created with password: $PASSWORD"
echo "Please record this information and keep it in a safe place."
echo "To remotely access this server, use the following command:"
echo "ssh warpspeed@$IPADDRESS"
