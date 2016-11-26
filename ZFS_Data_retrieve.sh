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

# 12 - Not a Solaris 10 host
# 13 - Not a ZFS filesystem

########
VERSION="1.00"
########

# Gobal variables


HNAME=$(uname -n)
PLATFORM=$(uname -s)

        if [[ $PLATFORM == SunOS ]] && [[ $(uname -r) == 5.10 ]] ; then
                echo ""
        else
                exit 12
        fi


#Identifying if ZFS, upfront

zpool list rpool > /dev/null 2>&1

 [ $? -eq 0 ] && VAR_A=`zpool status rpool |grep c[0-9] |awk '{print $1}'|head -1` && ZPOOL_FS=`fstyp /dev/rdsk/$VAR_A`

 if [[ "${ZPOOL_FS}" != "zfs" ]] ; then
        echo ""
        exit 13
 fi

space_identifier () {

ZFS_SPACE1=$(zpool list rpool |awk '/rpool/ {print $2,$3,$4}')
#  > /tmp/EBR_ZFS_Data_col.out

}
#MAIN
space_identifier

echo "$HNAME,$ZFS_SPACE1" > /tmp/EBR_ZFS_Data_col.out