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
    echo $(ifconfig eth0 | awk -F: '/inet addr:/ {print $2}' | awk '{ print $1 }')
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
    apt-get update
    apt-get -y upgrade
}

ws_setup_common_packages() {
    apt-get -y install python-software-properties build-essential git-core supervisor curl zlib1g-dev libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev zip unzip
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
    apt-get -y install unattended-upgrades
    cp templates/apt/10periodic /etc/apt/apt.conf.d/10periodic
    cp templates/apt/50unattended-upgrades/etc/apt/apt.conf.d/50unattended-upgrades
}

ws_setup_swap_space() {
    local SWAP=$(free -m | grep -oP '^Swap:[\s]*\K[0-9]*')
    local SIZE=$1
    if [ $SWAP -eq 0 ]; then
        fallocate -l $SIZE /swap
        mkswap /swap
        echo "/swap none swap sw 0 0" >> /etc/fstab
        swapon -ae
    fi
}

ws_setup_bash_profile() {
    cp -f $WARPSPEED_ROOT/templates/bash/.bash_profile ~/.bash_profile
    sed -i "s/{{user}}/$WARPSPEED_USER/g" ~/.bash_profile
    cp -f ~/.bash_profile /home/$WARPSPEED_USER/.bash_profile
    chown $WARPSPEED_USER:$WARPSPEED_USER /home/$WARPSPEED_USER/.bash_profile
}

ws_setup_ssh_keys() {
    local SSHKEY=$1
    mkdir -p /root/.ssh
    touch /root/.ssh/authorized_keys
    ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''
    ssh-keyscan -H github.com >> /root/.ssh/known_hosts
    ssh-keyscan -H bitbucket.org >> /root/.ssh/known_hosts
    if [ -n "$SSHKEY" ]; then
        # Add the warpspeed ssh key, overwriting any existing keys.
        echo "# WARPSPEED" > /root/.ssh/authorized_keys
        echo "$SSHKEY" >> /root/.ssh/authorized_keys
    fi
    # Setup proper permissions.
    chmod 0700 /root/.ssh
    chmod 0600 /root/.ssh/authorized_keys
    # Copy all files to warpspeed user.
    mkdir -p /home/$WARPSPEED_USER/.ssh
    cp -f /root/.ssh/* /home/$WARPSPEED_USER/.ssh/
    # Setup proper permissions.
    chmod 0700 /home/$WARPSPEED_USER/.ssh
    chown -R $WARPSPEED_USER:$WARPSPEED_USER /home/$WARPSPEED_USER/.ssh
}

ws_setup_fail2ban() {
    apt-get -y install fail2ban
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    sed -ri "/^\[ssh-ddos\]$/,/^\[/s/enabled[[:blank:]]*=.*/enabled = true/" /etc/fail2ban/jail.local
    ws_flag_service fail2ban
}

ws_setup_ssh_security() {
    sed -i "s/LoginGraceTime 120/LoginGraceTime 30/" /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    ws_flag_service ssh
}

ws_setup_firewall() {
    apt-get -y install ufw
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
