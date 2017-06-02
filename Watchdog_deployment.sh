#!/bin/bash

#PS4='$LINENO: '

#set -x

#set -n

###############################################################################
# (C) Copyright IBM Corporation, 2015
# All Rights Reserved
#
#      AUTHOR: Venudhar Chinthakuntla
# DESCRIPTION: Sliksftm daemon watchdog script deployment and enable.
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

# Gobal variables
HNAME=$(uname -n)
OS=$(uname)
TMPDIR=/var/tmp
Date=`date '+%Y%m%d%H%M%S'`

if [ "$OS" = "SunOS" ]; then
        PLATFORM="solaris"
        REL=$(uname -r)
        RC2DIR="/etc/rc2.d"
        RC0DIR="/etc/rc0.d"
        INITDIR="/etc/init.d"
elif [ "$OS" = "HP-UX" ]; then
        PLATFORM="hpux"
        RC2DIR="/sbin/rc2.d"
        RC0DIR="/sbin/rc0.d"
        INITDIR="/sbin/init.d"
elif [ "$OS" = "Linux" ]; then
        PLATFORM="linux"
        RC2DIR="/etc/rc.d/rc2.d"
        RC0DIR="/etc/rc.d/rc0.d"
        INITDIR="/etc/init.d"
else EC=14
fi
[ "${EC}" == "14" ] && echo "INFO: Unable to identify OS" && exit 14
##checking if daemon already exists

chk_dmn=$(crontab -l|grep -i sliksftm_dmn_monitor.sh |awk '{print $6}')
if  [ "${chk_dmn}" == "" ]; then 
	echo "INFO:daemon is not installed. Proceeding to install"
else
	echo "INFO: Daemon already exists"
	exit 15
fi

deploy_Kscript () {

# End of directorty identification which is to be backup in later stages
#ln -s  /etc/init.d/sliksftmd.solaris /etc/rc0.d/K99sliksftmd.solaris

 [ -f "$RC2DIR/S99sliksftmd.$PLATFORM" ] && ln -s "$INITDIR/sliksftmd.$PLATFORM" "$RC0DIR/K99sliksftmd.$PLATFORM"
 [ -f "$RC0DIR/K99sliksftmd.$PLATFORM" ] && echo "INFO: Kill script created successfully" || echo " ERROR creating kill script"

}



add_to_cron () {


if [ "$OS" = "SunOS" -o "$OS" = "HP-UX" ]; then
    if [ -f /var/spool/cron/crontabs/root ]; then
        cp -p /var/spool/cron/crontabs/root /var/spool/cron/crontabs/root.${Date}.bak
        [ $? -ne 0 ] && ( echo "ERROR: Can't take backup of old root crontab file"; exit 3 )
    else
	echo "INFO: Adding sliksftm monitoring daemon to CRON"        
	echo "# SLIKSFTM Daemon monitor" >> /var/spool/cron/crontabs/root
	[ $? -ne 0 ] && ( echo "ERROR: Can't take backup of old root crontab file"; exit 3 )
	echo ""
	exit 13
    fi
    
elif [ "$OS" = "Linux" ]; then
    if [ -f /var/spool/cron/root ]; then
        cp -p /var/spool/cron/root  /var/spool/cron/root.${Date}.bak
        [ $? -ne 0 ] && ( echo "ERROR: Can't take backup of old root crontab file"; exit 3 )
    elif [ -f /var/spool/cron/tabs/root ]; then
        cp -p /var/spool/cron/tabs/root /var/spool/cron/tabs/root.${Date}.bak
        [ $? -ne 0 ] && ( echo "ERROR: Can't take backup of old root crontab file"; exit 3 )
    else
        echo "Cron doesn't exist for root"
	exit 13
    fi
    
fi

}

update_cron () {
if [ "$OS" = "SunOS" -o "$OS" = "HP-UX" ]; then
	echo "# SLIKSFTM Daemon monitor" >> /var/spool/cron/crontabs/root
	[ $? -ne 0 ] && ( echo "ERROR: Unable to update crontab file"; exit 3 )
	echo "0,5,10,15,20,25,30,35,40,45,50,55 * * * * /usr/local/bin/sliksftm_dmn_monitor.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
	[ $? -ne 0 ] && ( echo "ERROR: Unable to update crontab file"; exit 3 )

elif  [ "$OS" = "Linux" ]; then
	 if [ -f /var/spool/cron/root ]; then
		echo "# SLIKSFTM Daemon monitor" >> /var/spool/cron/root
 		[ $? -ne 0 ] && ( echo "ERROR: Unable to update crontab file"; exit 3 )
		echo "0,5,10,15,20,25,30,35,40,45,50,55 * * * * /usr/local/bin/sliksftm_dmn_monitor.sh >/dev/null 2>&1" >> /var/spool/cron/root
 		[ $? -ne 0 ] && ( echo "ERROR: Unable to update crontab file"; exit 3 )
	else [ -f /var/spool/cron/tabs/root ]
		echo "# SLIKSFTM Daemon monitor" >> /var/spool/cron/tabs/root
 		[ $? -ne 0 ] && ( echo "ERROR: Unable to update crontab file"; exit 3 )
		echo "0,5,10,15,20,25,30,35,40,45,50,55 * * * * /usr/local/bin/sliksftm_dmn_monitor.sh >/dev/null 2>&1" >> /var/spool/cron/tabs/root
 		[ $? -ne 0 ] && ( echo "ERROR: Unable to update crontab file"; exit 3 )
	fi
fi
}



#MAIN

deploy_Kscript
add_to_cron
update_cron

##END##

