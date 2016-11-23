#!/bin/bash

#PS4='$LINENO: '

#set -x

################################################################################
# (C) Copyright IBM Corporation, 2016
# All Rights Reserved
#
#      AUTHOR: Venudhar Chinthakuntla
# DESCRIPTION: NBU 7.x.x.x PUSH script to NBU Clients. Scripts is heterogeneous to support on all UNIX/Linux platforms.
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

# 13 - Insufficient Disk Space
# 14 - Failed to create archive of the Base directory
# 15 - Unsupported Platform or unsupported current NB client version 
# 16 - Mount point not specified to check the avalible space
# 17 - Unable to bring down the Netbackup processess
# 18 - NBU client_config script failed partially or fully. 
# 19 - Binaries not found


####
VERSION="1.00"
####

# Gobal variables

HNAME=$(uname -n)
DATE=$(date "+%d%m%y %H:%M")
PLATFORM=$(uname -s)
VERSION=$(uname -r)
 
BASEDIR=/usr/openv
TEMP_VARTMP=/var/tmp
TEMP_CRASH=/var/crash
TEMP_SWAP=/tmp
Multiplier=1048576 # Convertion to GB 
MAGICNUMBER=2097153 # 2GB Min Space
BASE_TAR="CORE_DIR_BKUP_$(date +%Y%m%d).tar"


if [[ ${PLATFORM} == SunOS ]]; then

    if [[ -d ${TEMP_CRASH}/NBU773 ]]; then
        PKG_SOURCE=${TEMP_CRASH}/NBU773
    elif [[ -d ${TEMP_CRASH}/NBU7612 ]]; then
        PKG_SOURCE=${TEMP_CRASH}/NBU7612
    elif [[ -d ${TEMP_CRASH}/NBU7507 ]]; then
        PKG_SOURCE=${TEMP_CRASH}/NBU7507
    else
        RC=19
        logger "INFO: NBU packages not found. exiting with error code $RC...."
    fi
elif [[ ${PLATFORM} == Linux ]]; then
    if [[ -d ${TEMP_VARTMP}/NBU773]];then
        PKG_SOURCE=${TEMP_VARTMP}/NBU773
    elif [[ -d ${TEMP_VARTMP}/NBU7612 ]]; then
        PKG_SOURCE=${TEMP_VARTMP}/NBU7612
    elif [[ -d ${TEMP_VARTMP}/NBU7507 ]]; then
        PKG_SOURCE=${TEMP_VARTMP}/NBU7507
    else
        RC=19
        logger "INFO: NBU packages not found. exiting with error code $RC...."
    fi
        

logger () {

    # logger() - log the data to BL console.
    #
    # Function to ....
    #
    #   paramaters:     [$1]
    #
    #   returns:        [NONE]
    #
    #   requires:       [NONE]
    #
    #   side effects:   [NONE]

echo $1

}

space_identifier (){

    # platform_identifier () - Identify avalible disk space.
    #
    # Function to ....
    #
    #   paramaters:     Pass the mount point information 
    #
    #   returns:        [NONE]
    #
    #   requires:       [NONE]
    #
    #   side effects:   [NONE]   

    mntarg=$1
    minsparg=$2

    if [[ (X$mntarg == "X") || (X$minsparg == "X") ]]; then 
        logger "paramaters not passed to space check. exiting..."
        RC=16
        return 16
    fi

    if [ "$(df -k ${mntarg} |awk '/\// {print $4}')" -ge ${minsparg} ] ;then   # Min space is 800MB 
        echo pass 
    else
        echo fail
    fi
}

platform_identifier () {
    
    # platform_identifier () - Identify supported OS type or non-support OS.
    #
    # Function to ....
    #
    #   paramaters:     [NONE]
    #
    #   returns:        [NONE]
    #
    #   requires:       [NONE]
    #
    #   side effects:   [NONE]

if [[ "$PLATFORM" == "SunOS" ]]; then
        if [[ ("$VERSION" == "5.10") || ("$VERSION" == "5.9") ]]; then
            logger "INFO: [$PLATFORM] with version [$VERSION] is supported"
            RC=0
        else
            
            logger "INFO: [$PLATFORM] with version [$VERSION] is not supported"
            RC=15
        fi
fi  

#    elif [ $PLARFORM = Linux ]; then
#       echo "INFO: $PLATFORM with version $VERSION"
#    elif [ $PLARFORM = HP-UX ]; then
#        echo "INFO: $PLATFORM with version $VERSION"
#    else
#    echo "ERROR: $PLATFORM unidentified"
#    fi

}

pre_checks () {

    # pre_checks () - Check for which version of NB is currently installed and can this host can be upgradable to 7.7.3 version ir not.
    #
    # Function to ....
    #
    #   paramaters:     [NONE]
    #
    #   returns:        [NONE]
    #
    #   requires:       [ Version 6.5.x is minimum needed And Solaris 10 ]
    #
    #   side effects:   [NONE]


if [[ ($(awk '/Solaris/ {print $2}' /usr/openv/netbackup/bin/version) == 7.5) || ($(awk '/Solaris/ {print $2}' /usr/openv/netbackup/bin/version) == 7.5.[0-9].[0-9]) || ($(awk '/Solaris/ {print $2}' /usr/openv/netbackup/bin/version) == 6.5.[0-9]) ]]; then

        logger "INFO: Client [$HNAME] can be upgraded to NBU version 7.n.n.n"
        RC=0
    
    else

        RC=15
    fi    

}

backup_core_files () {

    # backup_core_dir () - Create the full backup file (tar) of the /usr/openv into /var/crash.
    #
    # Function to ....
    #
    #   paramaters:     [NONE]
    #
    #   returns:        [NONE]
    #
    #   requires:       [ Backup should not return error. Incase of NB Upgrade issues, we would have to restore the tar. ]
    #
    #   side effects:   [NONE]

 ### Descoped taking of backup of /usr/openv,  as per NBU Team advise ***

 #   if [[ -f "${TEMP_CRASH}/${BASE_TAR}" || -f "${TEMP_VARTMP}/${BASE_TAR}" || -f "${TEMP_SWAP}/${BASE_TAR}" ]] ; then
 #
 #       logger "INFO: A Backup was taken today. Ignoring taking of backup again"
 #   else 
 #       #No backup pre-exists
 #       openvbackup=$(du -sk /usr/openv|awk '{print $1}')
 #
 #       if [[ $(space_identifier ${TEMP_CRASH} ${openvbackup}) == "pass" ]] ; then
 #           _available_mnt=${TEMP_CRASH}
 #       
 #       elif [[ $(space_identifier ${TEMP_VARTMP} ${openvbackup}) == "pass" ]] ; then
 #           _available_mnt=${TEMP_VARTMP}
 #
 #       elif [[ $(space_identifier ${TEMP_SWAP} ${openvbackup}) == "pass" ]] ; then
 #           _available_mnt=${TEMP_SWAP}
 #        else
 #           RC=13
 #      fi
 #
 #       if [[ ${RC} -eq 13 ]] ; then 
 #           logger "___"
 #           return 13
 #       fi
 #
 #       logger "INFO: taking backup of curret NB version....."
 #       tar -cf "${_available_mnt}/${BASE_TAR}" "$BASEDIR" > /dev/null 2>&1
 #
 #       if [ $? -ne 0 ]; then
 #            logger "ERROR: Failed to backup the [$BASEDIR] on [$HNAME]."
 #          RC=14
 #

            logger "Taking backup of  config file.."

            [ ! -d "${TEMP_CRASH}/openv_old" ] && mkdir -p "${TEMP_CRASH}/openv_old"

            cp -rp /usr/openv/netbackup/bp.conf ${TEMP_CRASH}/openv_old/

            conffiles=/usr/openv/netbackup/exclude_list*

            [[ $conffiles ]] && cp -rp /usr/openv/netbackup/exclude_list* ${TEMP_CRASH}/openv_old/

            [ -f /usr/openv/netbackup/NET_BUFFER_SZ ] && cp -rp /usr/openv/netbackup/NET_BUFFER_SZ ${TEMP_CRASH}/openv_old/

            RC=0 
        
}

NB_shutdown () {

    # NB_shutdown () - bring down the NBU processess before performing backup and upgrade
    #
    # Function to ....
    #
    #   paramaters:     [NONE]
    #
    #   returns:        [ 0 or 17 ]
    #
    #   requires:       [NONE]
    #
    #   side effects:   [NONE]

    #Checking if NBackup processess are running

    if [[ $(/usr/openv/netbackup/bin/bpps -x|awk '/vnetd/||/bpcd/||/pbx/ {print $8$9}'|wc -l) -le "4" ]] ; then
        
        logger "INFO: Stoping Netbackup process...."
        [ -f "/etc/init.d/netbackup" ] && "/etc/init.d/netbackup" stop > /dev/null 2>&1 && sleep 1

        "/usr/openv/netbackup/bin/goodies/netbackup" stop > /dev/null 2>&1
        sleep 1
        "/opt/VRTSpbx/bin/vxpbx_exchanged" stop > /dev/null 2>&1
        sleep 1
        #checking if processess have stopped succesfully
        if [[ $(/usr/openv/netbackup/bin/bpps -x|awk '/vnetd/||/bpcd/||/pbx/ {print $8$9}'|wc -l) -eq "0" ]]; then
            
            logger "INFO: Netbackup Stopped succesfully"

            RC=0
        else 
            logger "ERROR: Unable to shutdown the processess. Manually stop the processess and re-trigger the BL Job"

            RC=17
        fi

    fi


}

client_upgrade () {

    # client_upgrade () - Perform the Netbackup upgrade to version 7.7.3
    #
    # Function to ....
    #
    #   paramaters:     [NONE]
    #
    #   returns:        [NONE]
    #
    #   requires:       [NONE]
    #
    #   side effects:   [NONE]

    coreopenvsize=1818904

if [[ $(space_identifier ${BASEDIR} ${coreopenvsize}) == "pass" ]] ; then
        

  # if [[ ($(awk '/Solaris/ {print $2}' /usr/openv/netbackup/bin/version) == 7.5.[0-9].[0-9]) || ($(awk '/Solaris/ {print $2}' /usr/openv/netbackup/bin/version) == 6.5.[0-9]) ]]; then


    #Trigger the upgraded
    
    cd $PKG_SOURCE
    umask 0022

    logger "INFO: Starting installation. Check the installation log [$TEMP_VARTMP/NBU_Install_log]"
    logger "............."

    sh "$PKG_SOURCE/client_config" > $TEMP_VARTMP/NBU_Install_log

        install_status=$(grep ^Client\ install\ complete\. /var/tmp/NBU_Install_log)

        if [[ ${install_status} == Client\ install\ complete\. ]] ; then

            logger "INFO: NBU_installation was successfully upgraded to [$(awk '/Solaris/ {print $2}' /usr/openv/netbackup/bin/version)]"
            
            

            RC=0
        else
            logger "Installation partially/fully failed. Issue is with NBU package which is not in BladeLogic controll. Please review the [$TEMP_VARTMP/NBU_Install_log] if the errors can be ignored"
            RC=18
        fi

else 
    logger "---"
    RC=13
fi

}
restore_config_files () {

    # restore_config_files () - Perform post config files restoration if upgraded to version 7.7.3
    #
    # Function to ....
    #
    #   paramaters:     [NONE]
    #
    #   returns:        [NONE]
    #
    #   requires:       [NONE]
    #
    #   side effects:   [NONE]

#If its upgraded to 7.7.3 then additional config files has to be restored

if [[ $(awk '/Solaris/ {print $2}' /usr/openv/netbackup/bin/version) == 7.7.3 ]]; then
    if [[ ! -d "${TEMP_CRASH}/openv_old/" ]]  ; then

        logger "INFO: No aditional config files are avalible to restore"

    else

        logger "Restoring backups of aditional config file.."
        cp -rp  "${TEMP_CRASH}/openv_old/bp.conf" "/usr/openv/netbackup/bp.conf" 
        conffiles.restoration= ${TEMP_CRASH}/openv_old/exclude_list*
        [[ "${conffiles.restoration}" ]] && cp -rp ${TEMP_CRASH}/openv_old/exclude_list* /usr/openv/netbackup/
        [[ -f "${TEMP_CRASH}/openv_old/NET_BUFFER_SZ" ]] && cp -rp "${TEMP_CRASH}/openv_old/NET_BUFFER_SZ"  "/usr/openv/netbackup/"
    fi
fi
}

NB_startup () {

#check if the curent version. if it upgraded or upgradation failed with issues.

    logger "INFO: Atempting to bring up NB process....."

    "/opt/VRTSpbx/bin/vxpbx_exchanged" start > /dev/null 2>&1
    sleep 1

    "/usr/openv/netbackup/bin/goodies/netbackup" start > /dev/null 2>&1
    sleep 1

     if [[ $(/usr/openv/netbackup/bin/bpps -x|awk '/vnetd/||/bpcd/||/pbx/ {print $8$9}'|wc -l) -le 4 ]] ; then 
         
         logger "INFO: NB Process started up successfully"
         RC=0
     else
        logger "INFO: Unable to start NB process.Please start manually"
        RC=19
     fi
}

clean_up () {

    rm -rf $PKG_SOURCE

}

# main

platform_identifier 
if [ $RC -ne 0 ]; then
    logger "ERROR: NBU_installation Failed with error code $RC."
    exit 1
else
    logger "......."

fi

#pre_checks
#if [ $RC -ne  0 ]; then
#   logger "ERROR: NBU_installation Failed with error code $RC."
#    exit 1
#else
 #   logger "......."

#fi

NB_shutdown
if [ $RC -ne 0 ]; then
    logger "ERROR: NBU_installation Failed with error code $RC."
    exit 1
else
    logger "......."

fi

backup_core_files 

#if [ $RC -ne 0 ]; then
#    logger "ERROR: NBU_installation Failed with error code $RC."
#    exit 1
#else
    logger "......."

#fi

client_upgrade

if [ $RC -ne 0 ]; then
    logger "ERROR: NBU_installation Failed with error code $RC."
    logger "INFO: Invoking the NB processess"

    NB_startup

    exit 1
else
    clean_up
    
    logger "......."

fi

restore_config_files

logger "......."

NB_startup

logger "......."

# end