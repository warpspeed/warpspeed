#!/bin/bash

if [ $(id -u) != "0" ]; then
    echo "This script must be run as root." 1>&2
    exit 1
fi

# Declare array to track installers that should be run.
# Installers are added via command line args by passing --installer.
INSTALLERS=()

# Retrieve system ip address.
IPADDRESS=$(ifconfig eth0 | awk -F: '/inet addr:/ {print $2}' | awk '{ print $1 }')

# Determine the directory this script is executing from.
SCRIPTS_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

echo $HOSTNAME > /etc/hostname
hostname -F /etc/hostname
sed -i "s/^127\.0\.1\.1.*/127\.0\.1\.1\t$HOSTNAME $HOSTNAME/" /etc/hosts

###############################################################################
# Set timezone to UTC
###############################################################################

ln -s -f /usr/share/zoneinfo/UTC /etc/localtime

###############################################################################
# Run system updates and install prerequisites.
###############################################################################

apt-get update
apt-get -y upgrade
apt-get -y install python-software-properties build-essential git-core

#apt-add-repository ppa:rwky/redis -y
#apt-add-repository ppa:chris-lea/node.js -y
#apt-add-repository ppa:ondrej/php5 -y

apt-get update

###############################################################################
# Install and configure unattended upgrades for security packages.
###############################################################################

apt-get -y install unattended-upgrades

# Configure auto update intervals and allowed origins.
cp templates/apt/10periodic /etc/apt/apt.conf.d/10periodic
cp templates/apt/50unattended-upgrades/etc/apt/apt.conf.d/50unattended-upgrades

###############################################################################
# Install and configure firewall.
###############################################################################

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

sed -i "s/LoginGraceTime 120/LoginGraceTime 30/" /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config
touch /tmp/restart-ssh

###############################################################################
# Install fail2ban and configure to protect ssh.
###############################################################################

apt-get -y install fail2ban
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sed -ri "/^\[ssh-ddos\]$/,/^\[/s/enabled[[:blank:]]*=.*/enabled = true/" /etc/fail2ban/jail.local
touch /tmp/restart-fail2ban

###############################################################################
# Add warpspeed user, set password, and enable sudo.
###############################################################################

useradd -m -s /bin/bash warpspeed
echo "warpspeed:$PASSWORD" | chpasswd
usermod -aG sudo warpspeed

###############################################################################
# Add ssh key for warpspeed user.
###############################################################################

# Add ssh key to authorized keys file for warpspeed user.
sudo -u warpspeed mkdir -p /home/warpspeed/.ssh
sudo -u warpspeed touch $USER_HOME/.ssh/authorized_keys
sudo -u warpspeed echo "# WARPSPEED USER" >> /home/warpspeed/.ssh/authorized_keys
sudo -u warpspeed echo "$SSHKEY" >> /home/warpspeed/.ssh/authorized_keys

# Update ssh key permissions.
chmod 0700 /home/warpspeed/.ssh
chmod 0600 /home/warpspeed/.ssh/authorized_keys

###############################################################################
# Setup bash profile.
###############################################################################

cp -f $SCRIPTS_ROOT/templates/bash/.bash_profile /home/warpspeed/.bash_profile
chown warpspeed:warpspeed /home/warpspeed/.bash_profile

###############################################################################
# Run all installers that were passed as arguments.
###############################################################################

for installer in "${INSTALLERS[@]}"; do
	INSTALLER_FULL_PATH="$SCRIPTS_ROOT/installers/$installer.sh"
	if [ -x "$INSTALLER_FULL_PATH" ]; then
		# Installer exists and is executable, run it.
		# Note: Installer scripts will have access to vars declared herein.
		source "$INSTALLER_FULL_PATH"
	fi
done

###############################################################################
# Restart services and show summary info.
###############################################################################

# Restarts services that have a restart-service_name file in /tmp.
for service_name in $(ls /tmp/ | grep restart-* | cut -d- -f2-10); do
    service $service_name restart
    rm -f /tmp/restart-$service_name
done

echo "Server initialization complete."
echo "User: warpspeed was created with password: $PASSWORD"
echo "Please record this information and keep it in a safe place."
echo "To remotely access this server, use the following command:"
echo "ssh warpspeed@$IPADDRESS"
