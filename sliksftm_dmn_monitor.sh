#!/bin/bash

#PS4='$LINENO: '

#set -x

################################################################################
# (C) Copyright IBM Corporation, 2015
# All Rights Reserved
#
#      AUTHOR: Venudhar Chinthakuntla
# DESCRIPTION: Script to monitor sliskftm and start if its down.
#
###############################################################################
#
# Version Control Repository:
# <location>
#
###############################################################################
#
# Editor Parameters
#
# Tabs represented as spaces: yes
# Max spaces in a tab: 8
# Indent Width: 4
#
###############################################################################


#Global




#SLIKSPID=`pgrep sliksftm|awk '{print $1}'`
SLIKSPID=`ps -ef|grep -i "/opt/sliksftm/bin/sliksftm"|grep -v grep|awk '{print $2}'`


OS=$(uname)
DATE=`date +%H:%M-on-%D`
LOGPATH=/var/log/sliksftm
STARTLOGFILE=laststat.log

if [ "$OS" = "SunOS" ]; then
        PLATFORM="solaris"
       	DNAME=sliksftmd.solaris
        INITDIR="/etc/init.d"
elif [ "$OS" = "HP-UX" ]; then
        PLATFORM="hpux"
	DNAME=sliksftmd.hpux
        INITDIR="/sbin/init.d"
elif [ "$OS" = "Linux" ]; then
        PLATFORM="linux"
	DNAME=sliksftmd.linux
        INITDIR="/etc/init.d"
else EC=14

fi
#MAIN

#Ensuring necessary files and directories exist.
[ ! -d ${LOGPATH} ] && ( echo "ERROR: Sliksftm log file is missing. Cross verify if sliksftm is installed and running"; exit 3 )
[ ! -f ${LOGPATH}/${STARTLOGFILE} ] && touch "${LOGPATH}/${STARTLOGFILE}" && chmod 775 "${LOGPATH}/${STARTLOGFILE}"

if [[ "${SLIKSPID}" -eq "" ]] ;then
	echo "Daemon is down when checked at $DATE. Starting it now" >> ${LOGPATH}/${STARTLOGFILE}
	#In order to clear the lock file, It is required to stop the daemon even its down.
        ${INITDIR}/${DNAME} stop
	sleep 1
	${INITDIR}/${DNAME} start
        sleep 1
        SLIKSPID1=`ps -ef|grep -i "/opt/sliksftm/bin/sliksftm"|grep -v grep|awk '{print $2}'`
        if [[ "${SLIKSPID1}" -gt "0" ]]; then
                echo "Daemon started and running with PID ${SLIKSPID}" 
        fi
else
        echo "Daemon is up and running with PID $SLIKSPID. No action required/performed in the last interval checked at $DATE" 
fi
