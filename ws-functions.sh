#!/bin/bash

WS_FUNCTIONS_DECLARED=1

ws_log_header() {
    echo -en "\n"
    echo "###############################################################################"
    echo "# $@"
    echo "###############################################################################"
    echo -en "\n"
}

ws_log_error() {
    echo -en "\n" 1>&2
    echo "*******************************************************************************" 1>&2
    echo "* Error: $@" 1>&2
    echo "*******************************************************************************" 1>&2
    echo -en "\n" 1>&2
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

ws_get_user() {
	id -u vagrant > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "vagrant"
	else
		echo "warpspeed"
	fi
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
	# Relies on $WS_HELPERS_DIR to be defined by caller.
	local WS_USER=$1
	local WS_DOMAIN=$2
	mkdir -p "/home/$WS_USER/repos/$WS_DOMAIN.git"
	cd "/home/$WS_USER/repos/$WS_DOMAIN.git"
	git init --bare
	cp $WS_HELPERS_DIR/../templates/git/post-receive /home/$WS_USER/repos/$WS_DOMAIN.git/hooks/post-receive
	sed -i "s/{{domain}}/$WS_DOMAIN/g" /home/$WS_USER/repos/$WS_DOMAIN.git/hooks/post-receive
	sed -i "s/{{user}}/$WS_USER/g" /home/$WS_USER/repos/$WS_DOMAIN.git/hooks/post-receive
	chmod +x "/home/$WS_USER/repos/$WS_DOMAIN.git/hooks/post-receive"
	chown -R $WS_USER:$WS_USER "/home/$WS_USER/repos/$WS_DOMAIN.git"
	echo "Use: git remote add web ssh://$WS_USER@$WS_DOMAIN/home/$WS_USER/repos/$WS_DOMAIN.git"
	echo "and: git push web +master:refs/heads/master"
}