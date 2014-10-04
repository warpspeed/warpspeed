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

ws_flag_service() {
	touch "/tmp/restart-$1"
	echo "Service: $1 has been flagged for restart."
}

ws_restart_flagged_services() {
	ws_log_header "Restarting services."
	for service_name in $(ls /tmp/ | grep restart-* | cut -d- -f2-10); do
	    service $service_name restart
	    rm -f /tmp/restart-$service_name
	done
}
