#!/bin/bash

#PS4='$LINENO: '

#set -x

################################################################################
# (C) Copyright IBM Corporation, 2016
# All Rights Reserved
#
#      AUTHOR: Venudhar Chinthakuntla
# DESCRIPTION: Basic NBU 7.X.x data collection on script
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

#Error Codes


HNAME=`uname -n`
FS_TYPE=""
MNT_OPENV=/usr/openv
MNT_ROOT=/
MNT_CRASH=/var/crash
MNT_TMP=/var/tmp
MNT_SWAP=/tmp
MNT_LOGS=$MNT_OPENV/netbackup/logs

##Zone validation


CSV=${HNAME}_out.csv

if [ ${HNAME}_out.csv ]; then
        touch ${HNAME}_out.csv
fi

if [[ $(uname -r) == "5.10" ]] && [[ $(pkgcond -n is_what|grep "is_global_zone=0") ]]
then echo "INFO: Please get the details from the global zone" 
echo "$HNAME,zone" > $CSV
exit 0
fi

zpool list rpool > /dev/null 2>&1
 [ $? -eq 0 ] && VAR_A=`zpool status rpool |grep c[0-9] |awk '{print $1}'|head -1` && ZPOOL_FS=`fstyp /dev/rdsk/$VAR_A` || ZPOOL_FS=NOZFS

VAR_B=`df -h / |grep -v Filesystem|awk -F/ '{print $5}'|awk '{print $1}'`
[ "$VAR_B" != "" ] && SVM_FS=`fstyp /dev/md/rdsk/$VAR_B`


if [ "${ZPOOL_FS}" == "zfs" ]; then
FS_TYPE=zfs
elif [ "${SVM_FS}" == "ufs" ]; then
FS_TYPE=ufs
fi


ROOT_SPACE=`df -k $MNT_ROOT|grep -v kbytes|awk '{print "'$MNT_ROOT'", $2, $4}'`
OPENV_SPACE=`df -k $MNT_OPENV|grep -v kbytes|awk '{print "'$MNT_OPENV'", $2, $4}'`
TMP_SPACE=`df -k $MNT_TMP|grep -v kbytes|awk '{print "'$MNT_TMP'", $2, $4}'`
SWAP_SPACE=`df -k $MNT_SWAP|grep -v kbytes|awk '{print "'$MNT_SWAP'", $2, $4}'`
CRASH_SPACE=`df -k $MNT_CRASH|grep -v kbytes|awk '{print "'$MNT_CRASH'", $2, $4}'`
OPENV_LOGS=`df -k $MNT_LOGS|grep -v kbytes|awk '{print "'$MNT_LOGS'", $2, $4}'`

#df -k /usr/openv |grep md|awk -F/ '{print $5}'|awk '{print $1}'
if [ $FS_TYPE == "ufs" ]; then
for mntpoint in /usr/openv /usr/openv/netbackup/logs; do
C=`df -k /usr/openv |grep md|awk -F/ '{print $5}'|awk '{print $1}'`
MAIN_META=`metastat -p $C|grep p|awk '{print $3}'`
[ "$MAIN_META" == ""  ] && MAIN_META=$C
#echo "openv is a softpartition on $MAIN_META"
FREE_SPACE=`metarecover -n -v ${MAIN_META} -p 2>/dev/null | awk 'BEGIN{x=0}/FREE/{x+=$5}END{print x/2/1024/1024 " GB"}'`
done
elif [  $FS_TYPE == "zfs" ]; then
MAIN_META=NA
FREE_SPACE=NA
fi
echo "$HNAME,$SERVER_TRPE,$FS_TYPE,$MAIN_META,$FREE_SPACE,$ROOT_SPACE,$TMP_SPACE,$OPENV_SPACE,$SWAP_SPACE,$CRASH_SPACE" > $CSV
#  "hostname, global, ........"
