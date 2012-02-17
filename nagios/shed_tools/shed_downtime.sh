#!/bin/bash

## ./cmd.cgi
# getcgivars(): Unsupported REQUEST_METHOD -> ''
#
# I'm guessing you're trying to execute the CGI from a command line.
# In order to do that, you need to set the REQUEST_METHOD environment
# variable to either "GET", "HEAD", or "POST".  When using the
# GET and HEAD methods, arguments can be passed to the CGI
# by setting the "QUERY_STRING" environment variable.  If you're
# using the POST method, data is read from standard input.  Also of
# note: if you've enabled authentication in the CGIs, you must set the
# "REMOTE_USER" environment variable to be the name of the user you're
# "authenticated" as.

METHOD="GET"
USER="nagiosadmin"

# 64 BIT
#NAGIOS_CMD="/usr/lib64/nagios/cgi-bin/cmd.cgi" 
# 32 BIT
NAGIOS_CMD="/usr/lib/nagios/cgi/cmd.cgi"

OK="OK"
FAIL="FAIL!"

DEBUG=0

helpstr="Usage: $0 -h <host> [-h <host>] [-H <hours>] [-m <minutes>]

 -h <host>	- The host you want to put into downtime.
 -H <hours>	- The number of hours you want the host(s) in downtime for [Default = 1].
 -m <minutes>   - The number of minutes you want the host(s) in downtime for. [Default = 0].
 -S <Start Date>   - The number of minutes you want the host(s) in downtime for. [Default = 0].
 -E <End Date>   - The number of minutes you want the host(s) in downtime for. [Default = 0].
 -f 		 - Used fix time (must use -S, -E). 
"

hosts=""
hour=1
minute=0
num_hosts=0
sdate=""
edate=""
FIXED=0

while getopts "h:H:m:S:E:f" option
do
	case $option in
		h) hosts="$hosts $OPTARG"
			let "num_hosts+=1";;
		H) hour=$OPTARG;;
		m) minute=$OPTARG;;
		S) sdate=$OPTARG;;
		E) edate=$OPTARG;;
		f) FIXED=1;;
		\?) echo "$helpstr"
			exit 3;;
	esac
done

if [ $num_hosts -eq 0 ]
then 
	echo "$helpstr"
	exit 3
fi

export REQUEST_METHOD="$METHOD"
export REMOTE_USER="$USER"

if [ $FIXED -eq 1 ]
then
	startdate="`date +"%m-%d-%Y+%H%%3A%M%%3A%S" -d"$sdate"`"
	enddate="`date +"%m-%d-%Y+%H%%3A%M%%3A%S" -d"$edate"`"
else
	startdate="`date +"%m-%d-%Y+%H%%3A%M%%3A%S"`"
	enddate="`date +"%m-%d-%Y+%H%%3A%M%%3A%S" -d"now +$hour hours +$minute minute"`"
fi

for host in $hosts
do


	echo -n "Putting '$host' into downtime for $hour:$minute (h:m)....."
	#Put the host into downtime
	export QUERY_STRING="cmd_typ=55&cmd_mod=2&host=$host&com_data=Put+into+downtime+by+blah&trigger=0&start_time=$startdate&end_time=$enddate&fixed=$FIXED&hours=$hour&minutes=$minute&childoptions=0&btnSubmit=Commit"
	$NAGIOS_CMD &> /dev/null
	if [ $DEBUG -eq 1 ]
	then
		echo $QUERY_STRING
	fi

	if [ $? -gt 0 ]
	then 
		echo $FAIL  
	else
		echo $OK
	fi


	echo -n  "Putting all services on '$host' into downtime for $hour:$minute (h:m)....."
	#Put all the services for the host into downtime. 
	export QUERY_STRING="cmd_typ=86&cmd_mod=2&host=$host&com_data=Put+into+downtime+by+blah&trigger=0&start_time=$startdate&end_time=$enddate&fixed=$FIXED&hours=$hour&minutes=$minute&btnSubmit=Commit"
	$NAGIOS_CMD %> /dev/null
	if [ $DEBUG -eq 1 ]
	then
		echo $QUERY_STRING
	fi

	if [ $? -gt 0 ]
	then 
		echo $FAIL  
	else
		echo $OK
	fi
done

