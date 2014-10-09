#!/bin/bash

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
    apt-get -y install python-software-properties build-essential git-core
}

ws_setup_bash_profile() {
    cp -f $WARPSPEED_ROOT/templates/bash/.bash_profile ~/.bash_profile
    sed -i "s/{{user}}/$WARPSPEED_USER/g" ~/.bash_profile
    cp -f ~/.bash_profile /home/$WARPSPEED_USER/.bash_profile
    chown $WARPSPEED_USER:$WARPSPEED_USER /home/$WARPSPEED_USER/.bash_profile
}

ws_setup_ssh_keys() {
    ssh-keygen -f /home/$WARPSPEED_USER/.ssh/id_rsa -t rsa -N ''
    ssh-keyscan -H github.com >> /home/$WARPSPEED_USER/.ssh/known_hosts
    ssh-keyscan -H bitbucket.org >> /home/$WARPSPEED_USER/.ssh/known_hosts
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
    ws_log_header "Restarting services."
    for service_name in $(ls /tmp/ | grep restart-* | cut -d- -f2-10); do
        sudo service $service_name restart
        rm -f /tmp/restart-$service_name
    done
}
