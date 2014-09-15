#!/bin/bash

if [ $(id -u) != "0" ]; then
    echo "This script must be run as root." 1>&2
    exit 1
fi

###############################################################################
# Input parameters.
###############################################################################

# Hostname of the server (required).
HOSTNAME=$1

# SSH public key for authentication (required).
SSHKEY=$2

# Password for warpspeed user (optional, defaults to system generated).
PASSWORD=$3

if [ -z "$HOSTNAME" ] || [ -z "$SSHKEY" ]; then
  echo "Usage: init-server.sh hostname sshkey [password]" 1>&2
  exit 1
fi

if [ -z "$PASSWORD" ]; then
    PASSWORD=`tr -cd '[:alnum:]' < /dev/urandom | fold -w20 | head -n1`
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
# Run system updates, and add new ppas.
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
# Restart services and show summary info.
###############################################################################

# Restarts services that have a restart-service_name file in /tmp.
for service_name in $(ls /tmp/ | grep restart-* | cut -d- -f2-10); do
    service $service_name restart
    rm -f /tmp/restart-$service_name
done

# Retrieve system ip address for display purposes.
IPADDRESS=$(ifconfig eth0 | awk -F: '/inet addr:/ {print $2}' | awk '{ print $1 }')

echo "Server initialization complete."
echo "User: warpspeed was created with password: $PASSWORD"
echo "Please record this information and keep it in a safe place."
echo "To remotely access this server, use the following command:"
echo "ssh warpspeed@$IPADDRESS"

exit 0