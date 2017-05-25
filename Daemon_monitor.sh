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
DNAME=sliksftmd.solaris
DAEMONPATH=/etc/init.d
LOGPATH=/var/log/sliksftm
STARTLOGFILE=laststat.log

#MAIN

[ ! -d ${LOGPATH} ] && mkdir ${LOGPATH}

if [ ${SLIKSPID[0]} -eq 0 ] ;then
        echo "Daemon is down. Starting it now" > ${LOGPATH}/${STARTLOGFILE}
        ./${DAEMONPATH}/${DNAME} restart
        sleep 10
        if [ ${SLIKSPID} -ne 0 ]; then
                echo "Daemon started and running with PID ${SLIKSPID}" >> ${LOGPATH}/${STARTLOGFILE}
        fi
else
        echo "Daemon is up and running with PID $SLIKSPID. No action required/performed in the last interval check" > ${LOGPATH}/${STARTLOGFILE}
fi

