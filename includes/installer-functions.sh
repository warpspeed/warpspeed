#!/bin/bash

# Visit http://warpspeed.io for complete information.
# (c) Turner Logic, LLC. Distributed under the GNU GPL v2.0.

ws_log_header() {
    echo -en "\n"
    echo "###############################################################################"
    echo "# $@"
    echo "###############################################################################"
    echo -en "\n"
}

ws_require_root() {
    if [ $(id -u) != "0" ]; then
        echo "This script must be run as root." 1>&2
        exit 1
    fi
}

ws_get_ip_address() {
    echo $(ifconfig eth0 | grep "inet " | awk -F'[: ]+' '{ print $3 }')
}

ws_set_hostname() {
    local HOSTNAME=$1
    echo $HOSTNAME > /etc/hostname
    hostname -F /etc/hostname
    sed -i "s/^127\.0\.1\.1.*/127\.0\.1\.1\t$HOSTNAME $HOSTNAME/" /etc/hosts
}

ws_set_timezone() {
    local TIMEZONE=$1
    ln -s -f /usr/share/zoneinfo/$TIMEZONE /etc/localtime
}

ws_run_system_updates() {
    apt update
    apt -y upgrade
}

ws_setup_common_packages() {
    apt -y install software-properties-common build-essential git supervisor curl zlib1g-dev libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev zip unzip libgmp-dev
}

ws_create_user() {
    local USER=$1
    local PASS=$2
    shift 2
    useradd -m -s /bin/bash $USER
    echo "$USER:$PASS" | chpasswd
    for group in "$@"; do
        adduser $USER $group
    done
    # Make sure home directory permissions are correct.
    chown -R $USER:$USER /home/$USER
}

ws_setup_automatic_updates() {
    apt -y install unattended-upgrades update-notifier-common
    cp -f $WARPSPEED_ROOT/templates/apt/10periodic /etc/apt/apt.conf.d/10periodic
    cp -f $WARPSPEED_ROOT/templates/apt/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades
    cp -f $WARPSPEED_ROOT/templates/apt/50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades
}

ws_setup_swap_space() {
    # View existing swap with: "swapon --show" and: "free -h".
    local SWAP=$(free -m | grep -oP '^Swap:[\s]*\K[0-9]*')
    local SIZE=$1
    # Only allocate if there is no exising swap.
    if [ $SWAP -eq 0 ]; then
        # Allocate, protect, and make the swapfile.
        fallocate -l $SIZE /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        # Backup the fstab file and then update the configuration.
        cp /etc/fstab /etc/fstab.orig
        echo "/swapfile none swap sw 0 0" >> /etc/fstab
        swapon -ae
    fi
}

ws_setup_bash_profile() {
    # Setup the .bashrc file.
    cp -f $WARPSPEED_ROOT/templates/bash/.bashrc ~/.bashrc
    sed -i "s/{{user}}/$WARPSPEED_USER/g" ~/.bashrc
    cp -f ~/.bashrc /home/$WARPSPEED_USER/.bashrc
    chown $WARPSPEED_USER:$WARPSPEED_USER /home/$WARPSPEED_USER/.bashrc
    # Setup the .bash_profile file.
    cp -f $WARPSPEED_ROOT/templates/bash/.bash_profile ~/.bash_profile
    cp -f ~/.bash_profile /home/$WARPSPEED_USER/.bash_profile
    chown $WARPSPEED_USER:$WARPSPEED_USER /home/$WARPSPEED_USER/.bash_profile
}

ws_setup_ssh_keys() {
    local SSHKEY=$1
    # Ensure directories exist.
    mkdir -p /root/.ssh
    mkdir -p /home/$WARPSPEED_USER/.ssh
    # Generate the server key pair.
    ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''
    # Copy key to warpspeed user.
    cp -f /root/.ssh/id_rsa /home/$WARPSPEED_USER/.ssh/
    cp -f /root/.ssh/id_rsa.pub /home/$WARPSPEED_USER/.ssh/
    # Generate known hosts file.
    ssh-keyscan -H github.com >> /root/.ssh/known_hosts
    ssh-keyscan -H bitbucket.org >> /root/.ssh/known_hosts
    # Copy known hosts file.
    cp -f /root/.ssh/known_hosts /home/$WARPSPEED_USER/.ssh/
    if [ -n "$SSHKEY" ]; then
        # Add the warpspeed ssh key for root, overwriting any existing keys.
        echo "# WARPSPEED" > /root/.ssh/authorized_keys
        echo "$SSHKEY" >> /root/.ssh/authorized_keys
        chmod 0600 /root/.ssh/authorized_keys
        # Append the warpspeed ssh key for the warpspeed user (prevent overwrite of vagrant key).
        echo "# WARPSPEED" >> /home/$WARPSPEED_USER/.ssh/authorized_keys
        echo "$SSHKEY" >> /home/$WARPSPEED_USER/.ssh/authorized_keys
        chmod 0600 /home/$WARPSPEED_USER/.ssh/authorized_keys
    fi
    # Setup proper permissions.
    chmod 0700 /root/.ssh
    chmod 0700 /home/$WARPSPEED_USER/.ssh
    chown -R $WARPSPEED_USER:$WARPSPEED_USER /home/$WARPSPEED_USER/.ssh
}

ws_setup_fail2ban() {
    apt -y install fail2ban
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    # Enable jails for sshd and sshd-ddos.
    sed -i "/^\[sshd\]$/a enabled = true" /etc/fail2ban/jail.local
    sed -i "/^\[sshd-ddos\]$/a enabled = true" /etc/fail2ban/jail.local
    ws_flag_service fail2ban
}

ws_setup_ssh_security() {
    # Backup sshd_config file.
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
    # Decrease login grace time and disable password authentication.
    sed -i "s/LoginGraceTime 120/LoginGraceTime 30/" /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    ws_flag_service ssh
}

ws_setup_firewall() {
    apt -y install ufw
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
}

ws_run_installers() {
    for installer in "$@"; do
        local INSTALLER_FULL_PATH="$WARPSPEED_ROOT/installers/$installer.sh"
        if [ -f "$INSTALLER_FULL_PATH" ]; then
            # Installer exists and is executable, run it.
            # Note: Installer scripts will have access to vars declared herein.
            source "$INSTALLER_FULL_PATH"
        fi
    done
}

ws_flag_service() {
    touch "/tmp/restart-$1"
    echo "Service: $1 has been flagged for restart."
}

ws_restart_flagged_services() {
    for service_name in $(ls /tmp/ | grep restart-* | cut -d- -f2-10); do
        sudo service $service_name restart
        rm -f /tmp/restart-$service_name
    done
}
