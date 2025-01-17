#!/bin/bash
#
# chkconfig: 2345 20 80
# description: Jool NAT64 service

### BEGIN INIT INFO
# Provides:          jool
# Required-Start:    $remote_fs $syslog $network
# Required-Stop:     $remote_fs $syslog $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Jool NAT64 service
# Description:       IP/ICMP translation, stateful version.
### END INIT INFO

. /lib/lsb/init-functions

# IF YOU INTEND TO MODIFY THIS FILE, NOTE THAT YOU WILL MOST LIKELY NEED TO
# CASCADE THE CHANGES TO JOOL_SIIT, BECAUSE IT'S MOSTLY EXACTLY THE SAME.

module_name=jool
jool_bin=/usr/local/bin/$module_name
config_file=/etc/jool/$module_name.conf

check_permissions() {
	if [ $1 -eq -1 ] || [ $1 -eq 1 ]; then
		exit 4 # Not enough privileges
	fi
}

check_workspace() {
	if [ ! -f "$jool_bin" ]; then
		exit 5 # Program not installed
	fi
	if [ ! -f "$config_file" ]; then
		exit 6 # Program not configured
	fi
}

check_result() {
	check_permissions $1
	if [ $1 -ne 0 ]; then
		exit 1 # Generic error
	fi
}

# You're expected to read $status after calling this function.
# The allowed results are "Running", "Dead" and anything else.
compute_status() {
	status=$($jool_bin -f "$config_file" instance status 2> /dev/null)
	check_permissions $?
	status=$(echo "$status" | head -1)
}

add_module() {
	/sbin/modprobe $module_name
	check_result $?
}

add_instance() {
	$jool_bin file handle "$config_file"
	check_result $?
}

remove_instance() {
	$jool_bin -f "$config_file" instance remove
	check_result $?
}

# start - start the service
# (...) the following situations are also to be considered successful: (...)
# running start on a service already running
start() {
	check_workspace

	compute_status
	case "$status" in
		Running)
			exit 0
			;;
		Dead)
			add_module
			add_instance
			exit 0
			;;
		*)
			exit 1
			;;
	esac
}

# stop - stop the service
# (...) the following situations are also to be considered successful: (...)
# running stop on a service already stopped or not running
stop() {
	check_workspace

	compute_status
	case "$status" in
		Running)
			remove_instance
			exit 0
			;;
		Dead)
			exit 0
			;;
		*)
			exit 1
			;;
	esac
}

# restart - stop and restart the service if the service is already running,
# otherwise start the service
# (...) the following situations are also to be considered successful: (...)
# running restart on a service already stopped or not running
restart() {
	check_workspace

	compute_status
	case "$status" in
		Running)
			remove_instance
			add_instance
			exit 0
			;;
		Dead)
			add_module
			add_instance
			exit 0
			;;
		*)
			exit 1
			;;
	esac
}

# try-restart - restart the service if the service is already running
# (...) the following situations are also to be considered successful: (...)
# running try-restart on a service already stopped or not running
try_restart() {
	check_workspace

	compute_status
	case "$status" in
		Running)
			remove_instance
			add_instance
			exit 0
			;;
		Dead)
			exit 0
			;;
		*)
			exit 1
			;;
	esac
}

# reload - cause the configuration of the service to be reloaded without
# actually stopping and restarting the service
#
# (Hypothesis: reload will never be called on a dead service. This is why it
# doesn't define what happens then.)
#
# force-reload - cause the configuration to be reloaded if the service supports
# this, otherwise restart the service if it is running
# (...) the following situations are also to be considered successful:
# restarting a service (instead of reloading it) with the force-reload argument
#
# (Note: Strange wording. Paraphrasis: If the service supports reload, then
# reload. Otherwise try_restart.)
# (Warning: The haphazard use of the word 'restart' means that I've no idea if
# the 'also successful situation' applies here or not.)
reload() {
	check_workspace
	add_module
	# `file handle` on an already existing instance is considered an update.
	add_instance
}

# status - print the current status of the service
status() {
	output=$($jool_bin -f "$config_file" instance status)
	echo "$output"

	status=$(echo "$output" | head -1)
	case "$status" in
		Running)
			exit 0 # Running
			;;
		Dead)
			exit 3 # Not running
			;;
		*)
			exit 4 # Unknown
			;;
	esac
}

case "$1" in
	start)
		start
		;;
	stop)
		stop
		;;
	restart)
		restart
		;;
	try-restart)
		try_restart
		;;
	reload | force-reload)
		reload
		;;
	status)
		status
		;;
	*)
		echo "Usage: $0 {start|stop|restart|try-restart|reload|force-reload|status}"
		exit 3 # Unimplemented feature
		;;
esac

exit 0