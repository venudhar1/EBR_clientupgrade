#!/bin/bash

#PS4='$LINENO: '

#set -x

################################################################################
# (C) Copyright IBM Corporation, 2016
# All Rights Reserved
#
#      AUTHOR: Venudhar Chinthakuntla
# DESCRIPTION: /usr/openv FS resize on Linux hosts(Redhat 5.x to current versions and Suse 9.x to current versions).
#
###############################################################################
#
# Version Control Repository:
# <~/EBR_NBU_Upgrade/Core_Scripts>
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

#Error Codes

# 12 - Not a Linux host

########
VERSION="1.00"
########

# Gobal variables
HNAME=$(uname -n)
PLATFORM=$(uname -s)

if [[ $PLATFORM != Linux ]] ; then
	exit 12
fi


if [[ -f /etc/redhat-release ]] ; then 
	RELEASENAME=REDHAT
	LINUX_VERSION=$(awk '{print $(NF-1)}' /etc/redhat-release)
elif [[ -f /etc/SuSE-release ]] ; then
	RELEASENAME=SuSE
	LINUX_VERSION=$(awk '/VERSION/ {print $3}' /etc/SuSE-release)
else
		echo "Error "
		exit 12
fi

free_space_identifier () {
MNTPNT1=$1

	if [[ $RELEASENAME == REDHAT ]] ; then
		 VG_NAME=`df -hP $MNTPNT1|awk -F['/-'] '/\/dev\/mapper\// {print $4}'`
		 FREE_SPACE=`vgs |grep -i ${VG_NAME} |awk '{print $7}'` 
		 Current_Available_Space=`df -hP  $MNTPNT1 | awk '/\/dev/ {print $4}'`
		elif [[ $RELEASENAME == SuSE ]]; then
		 VG_NAME=`df -hP $MNTPNT1|awk -F['/-'] '/\/dev\/mapper\// {print $4}'`
		 FREE_SPACE=`vgs |grep -i ${VG_NAME} |awk '{print $7}'`
		 Current_Available_Space=`df -hP  $MNTPNT1 | awk '/\/dev/ {print $4}'`
		else
			echo "ERROR: 13"
		fi
echo "$MNTPNT1,$Current_Available_Space,$VG_NAME,$FREE_SPACE"
}		

#MAIN

echo "$HNAME,$LINUX_VERSION,$(free_space_identifier /usr/openv),$(free_space_identifier /tmp),$(free_space_identifier /var/tmp),$(free_space_identifier /usr/openv/netbackup/logs),$(df -hP /usr/openv/netbackup/logs|awk '/\/dev/ {print $2}')" > /tmp/Linux_NBU.csv