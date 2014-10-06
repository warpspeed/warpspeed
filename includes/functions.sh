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

ws_create_git_push_deploy_repo() {
    local SITE_NAME=$1
    mkdir -p "/home/$WARPSPEED_USER/repos/$SITE_NAME.git"
    cd "/home/$WARPSPEED_USER/repos/$SITE_NAME.git"
    git init --bare
    cp $WARPSPEED_ROOT/templates/git/post-receive /home/$WARPSPEED_USER/repos/$SITE_NAME.git/hooks/post-receive
    sed -i "s/{{domain}}/$SITE_NAME/g" /home/$WARPSPEED_USER/repos/$SITE_NAME.git/hooks/post-receive
    chmod +x "/home/$WARPSPEED_USER/repos/$SITE_NAME.git/hooks/post-receive"
    chown -R $WARPSPEED_USER:$WARPSPEED_USER "/home/$WARPSPEED_USER/repos/$SITE_NAME.git"
    echo "Use: git remote add web ssh://$WARPSPEED_USER@$SITE_NAME/home/$WARPSPEED_USER/repos/$SITE_NAME.git"
    echo "and: git push web +master:refs/heads/master"
}

ws_create_site_structure() {
    local SITE_NAME=$1
    mkdir -p "/home/$USER/sites/$SITE_NAME"
    mkdir -p "/home/$USER/sites/$SITE_NAME/public"
    mkdir -p "/home/$USER/sites/$SITE_NAME/tmp"
    mkdir -p "/home/$USER/sites/$SITE_NAME/logs"
    chown -R $WARPSPEED_USER:$WARPSPEED_USER /home/$WARPSPEED_USER/sites/$SITE_NAME
}

ws_create_nginx_site() {
    local SITE_NAME=$1
    local SITE_TEMPLATE=$2
    sudo cp $WARPSPEED_ROOT/templates/nginx/$SITE_TEMPLATE /etc/nginx/sites-available/$SITE_NAME
    sudo sed -i "s/{{domain}}/$SITE_NAME/g" /etc/nginx/sites-available/$SITE_NAME
    sudo sed -i "s/{{user}}/$WARPSPEED_USER/g" /etc/nginx/sites-available/$SITE_NAME
    sudo ln -s /etc/nginx/sites-available/$SITE_NAME /etc/nginx/sites-enabled/$SITE_NAME
}
