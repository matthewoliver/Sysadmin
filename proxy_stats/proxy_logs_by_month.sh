#!/bin/bash

ACCESS_LOG_DIR="/var/log/squid/access.log*"
MONTH="$1"

function getFirstLine() {
	if [ -n  "`echo $1 |grep "gz$"`" ]
	then
		zcat $1 |head -n 1
	else
		head -n 1 $1 
	fi
}

function getLastLine() {
	if [ -n  "`echo $1 |grep "gz$"`" ]
	then
		zcat $1 |tail -n 1
	else
		tail -n 1 $1 
	fi
}

for log in `ls $ACCESS_LOG_DIR`
do
	firstLine="`getFirstLine $log`"
	epochStr="`echo $firstLine |awk '{print $1}'`"
	month=`date -d @$epochStr +%m`
	
	if [ "$month" -eq "$MONTH" ]
	then
		echo $log
		continue
	fi

	
	#Check the last line
	lastLine="`getLastLine $log`"
	epochStr="`echo $lastLine |awk '{print $1}'`"
        month=`date -d @$epochStr +%m`

        if [ "$month" -eq "$MONTH" ]
        then
                echo $log
        fi
	
done
