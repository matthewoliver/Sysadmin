#!/bin/bash

WORKINGDIR="$( cd "$( dirname "$0" )" && pwd )"
source "$WORKINGDIR/settings.sh"

function get_nagios_config_files() {
	filter="$1"
	grep cfg_file $NAGIOS_CONFIG |grep -v "^#" |awk -F '=' '{print $2}'
}

function get_hosts_from_config() {
	filter="$2"
	cfg="$1"
	if [ $FILTER -eq 0 ]
	then
		grep host_name $cfg |grep -v "^#" |awk '{print $2}' |sort |uniq
	else
		grep host_name $cfg |grep -v "^#" |awk '{print $2}' |sort |uniq |grep $filter
	fi
}

function get_all_hosts() {
	filter="$1"
	for cfg in `get_nagios_config_files "$filter"`
	do
		if [ $FILTER -eq 0 ]
		then
			get_hosts_from_config "$cfg"
		else
			get_hosts_from_config "$cfg" "$filter"
		fi
	done
}

function get_all_groups() {
	filter="$1"
	for cfg in `get_nagios_config_files "$filter"`
	do
		if [ $FILTER -eq 0 ]
		then
			grep hostgroup_name $cfg |grep -v "^#" |awk '{print $2}' |sort |uniq
		else
			grep hostgroup_name $cfg |grep -v "^#" |awk '{print $2}' |sort |uniq |grep $filter
		fi
	done
}


SHED_DOWNTIME_CMD="$WORKINGDIR/shed_downtime.sh"

ALL=0
LIST_GROUPS=1
LIST_CONFIGS=2
GROUP=3
CONFIG=4

FILTER=0
F_PARAM=""
SHED_DOWNTIME=0
hour=1
minute=0
sdate=""
edate=""
fixed=0

mode=$ALL
param=""

helpstr="Usage $0 [<option>]

  -a			- List all hosts (default).
  -G			- List all groups.
  -C			- List all configs.
  -g <host_group>	- List all hosts belonging to the host_group.
  -c <config file>	- List all hosts beloning to config file.
  -f <filter>		- Add a filter (grep).
  -H <hour>		- Set the number of hours for downtime [Used with the -s switch] (Default: 1).
  -M <minute>		- Set the number of minutes for downtime [Used with the -s switch] (Default: 0).
  -S <Start Date>	- Set the number of minutes for downtime [Used with the -s switch] (Default: 0).
  -E <End Date>		- Set the number of minutes for downtime [Used with the -s switch] (Default: 0).
  -s 			- Shedule downtime for resulting hosts. 

"

while getopts "aGCg:c:hf:sH:M:S:E:" option
do
        case $option in
                a) mode=$ALL;;
                G) mode=$LIST_GROUPS;;
                C) mode=$LIST_CONFIGS;;
                g) mode=$GROUP
			param="$param $OPTARG";;
                c) mode=$CONFIG
			param="$param $OPTARG";;
                f) FILTER=1
			F_PARAM="$OPTARG";;
                H) hour="$OPTARG";;
                M) minute="$OPTARG";;
                S) sdate="$OPTARG";;
                E) edate="$OPTARG";;
		s) SHED_DOWNTIME=1;;
                h) echo "$helpstr"
                        exit 0;;
                \?) echo "$helpstr"
                        exit 3;;
        esac
done

if [ -n "$sdate" -a -n "$edate" ]
then
	fixed=1
fi

if [ $SHED_DOWNTIME -eq 0 ]
then
	case $mode in
		$ALL) get_all_hosts "$F_PARAM";;
		$LIST_GROUPS) get_all_groups "$F_PARAM";;
		$LIST_CONFIGS) get_nagios_config_files  "$F_PARAM";;
		$GROUP) echo "not implemented";;
		$CONFIG) get_hosts_from_config "$param" "$F_PARAM";;
	esac
else
	# SHED Downtime
	case $mode in
		$ALL) hosts="`get_all_hosts "$F_PARAM"`";;
		$LIST_GROUPS) hosts=""
			get_all_groups "$F_PARAM";;
		$LIST_CONFIGS) hosts = ""
			get_nagios_config_files  "$F_PARAM";;
		$GROUP) echo "not implemented";;
		$CONFIG) hosts="`get_hosts_from_config "$param" "$F_PARAM"`";;
	esac
	
	if [ -z "$hosts" ]
	then
		echo "No hosts!"
		exit 0
	else
		for host in $hosts
		do
			if [ $fixed -eq 0 ]
			then
				$SHED_DOWNTIME_CMD -h $host -H $hour -m $minute
			else
				$SHED_DOWNTIME_CMD -h $host -H $hour -m $minute -S "$sdate" -E "$edate" -f $fixed
			fi
		done
	fi
fi
