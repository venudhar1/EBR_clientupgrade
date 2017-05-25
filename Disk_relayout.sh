#!/bin/bash

# relative path

BASEDIR=/usr/openv
TEMP_VARTMP=/var/tmp
TEMP_CRASH=/var/crash
TEMP_SWAP=/var/run
BASEDIR_LOG=${BASEDIR}/netbackup/logs
PLATFORM=`uname -s`
BASE_TAR="CORE_DIR_BKUP_$(date +%Y%m%d).tar"

_max_tar_size=`du -sk ${BASEDIR}|awk '{print $1}'`
_req_tar_space=`expr ${_max_tar_size} + 204800`

_underlying_openvmnt=`df -k ${BASEDIR}|awk '/\// {print $NF}'`
_underlying_nblogsmnt=`df -k ${BASEDIR_LOG}|awk '/\// {print $NF}'`


_usropenvnetbackuplogssp=`df -k ${BASEDIR_LOG}|awk -F/ '/\// {print $5}'|awk '{print $1}'`
_usropenvnetbackuplogsmd=`metastat -p ${_usropenvnetbackuplogssp}|awk '/p/ {print $3}'`
[ $? -ne 0 ] && exit 11

RC=0

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
        echo "paramaters not passed to space check. exiting..."
        RC=16
        return 16
    fi
if [[ ${PLATFORM} == SunOS ]]; then
    if [ "$(df -k ${mntarg} |awk '/\// {print $4}')" -ge ${minsparg} ] ;then   
        echo pass 
    else
        echo fail
    fi
elif [[ ${PLATFORM} == Linux ]]; then
    
    if [ "$(df -kP ${mntarg} |awk '/\// {print $4}')" -ge ${minsparg} ] ;then   
        echo pass 
    else
        echo fail
    fi
fi
}


go_no-go () {
	
	#check 1 should return pass
	#check 2 should return pass
	# then good to proceed else exit
	#check1

RC=0

if [[ $(space_identifier ${TEMP_VARTMP} ${_req_tar_space}) == "pass" ]] ; then
            _available_mnt=${TEMP_VARTMP}
       
        elif [[ $(space_identifier ${TEMP_SWAP} ${_req_tar_space}) == "pass" ]] ; then
            _available_mnt=${TEMP_SWAP}

        elif [[ $(space_identifier ${TEMP_CRASH} ${_req_tar_space}) == "pass" ]] ; then
            _available_mnt=${TEMP_CRASH}
        else
            RC=13
        fi
#1 - Space Cheker 
if [[ $RC -ne 0 ]]; then
	echo "FAILED: Space check failed. exiting.."
	exit 13
elif [[ ${_available_mnt} != "" ]]; then
	echo "PASSED: Space is avalible to backup /usr/openv"
fi
#2 - Scenario 1 checker

if [ ${_underlying_openvmnt} == \/ ] && [ X${_underlying_openvmnt} != X ] ; then 

	if [ ${_underlying_nblogsmnt} != \/ ] && [ X${_underlying_nblogsmnt} != X ] ; then
		echo "PASSED: netbackup/logs is not under root"

	else
		RC=15
	fi
	echo "PASSED: /usr/openv is under /"
else
	RC=15
fi
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
        
        echo "INFO: Stoping Netbackup process...."
        [ -f "/etc/init.d/netbackup" ] && "/etc/init.d/netbackup" stop > /dev/null 2>&1 && sleep 1

        "/usr/openv/netbackup/bin/goodies/netbackup" stop > /dev/null 2>&1
        sleep 1
        "/opt/VRTSpbx/bin/vxpbx_exchanged" stop > /dev/null 2>&1
        sleep 1
        #checking if processess have stopped succesfully
        if [[ $(/usr/openv/netbackup/bin/bpps -x|awk '/vnetd/||/bpcd/||/pbx/ {print $8$9}'|wc -l) -eq "0" ]]; then
            
            echo "PASSED: Netbackup Stopped succesfully"

            RC=0
        else 
            echo "FAILED: Unable to shutdown the processess. Manually stop the processess and re-run script"

            RC=17
        fi

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

 
    if [[ -f "${_available_mnt}/${BASE_TAR}" ]] ; then
 
        echo "INFO: A Backup was taken today. Ignoring taking of backup again"
    else 
      
       echo "INFO: taking backup of curret NB version....."
        tar -cf "${_available_mnt}/${BASE_TAR}" "$BASEDIR" > /dev/null 2>&1

       if [ $? -ne 0 ]; then
            echo "ERROR: Failed to backup the [$BASEDIR]."
          RC=14
      else
	echo "PASSED: openv backup was taken successfully"
	fi
  fi
  }


basix_math () {

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

	#total netbackup logs is to be divided in 90:10 ratio
	multiplier=1048576
	_A=`df -k ${BASEDIR_LOG}|awk '/\/md/ {print $2}'`
	_B=`expr ${_A} / 100`
	_C=`expr ${_B} \* 70` #Amount of space to be assigned to /usr/openv/  90 % of total 
	_D=`expr ${_B} \* 30` #Amount of space to be assigned to /usr/openv/netbackup/logs 10% of total
	size_for_openv=`expr ${_C} / ${multiplier}`
	echo "calculated size for openv is ${size_for_openv}g"
	size_for_nblogs=`expr ${_D} / ${multiplier}`
	echo "calculated size for nb logs is ${size_for_nblogs}g"

}




free_sp_identifier () {


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


for i in `metastat -p |awk '{print $1}'|tr -d :[[:alpha:]]:`;
do [[ $i -eq $1 ]] && echo "failed";
done

}



nb_softslice_relayout () {

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

	umount "/usr/openv/netbackup/logs"
	[ $? -eq 0 ] && echo "PASSED: unmounted netbackuplogs filesystem" || (echo "FAILED: unmount netbackuplogs filesystem"; exit 4)
	echo "=================="
	echo "Executing command \"metaclear ${_usropenvnetbackuplogssp}\" "
	read -p "Press enter to continue"
	metaclear ${_usropenvnetbackuplogssp}

	[ $? -eq 0 ] && echo "PASSED: Cleared netbackup/logs softpartition ${_usropenvnetbackuplogssp}" || (echo "FAILED: Cleared netbackup/logs softpartition ${_usropenvnetbackuplogssp}" ; exit 4)
	echo "=================="
	echo "Creating Softpartition for nblogs. Executing command \"metainit $locked_nblog -p ${_usropenvnetbackuplogsmd}  ${size_for_nblogs}g \" "
	read -p "Press enter to continue"

	metainit $locked_nblog -p ${_usropenvnetbackuplogsmd}  ${size_for_nblogs}g      #for /usr/openv/netbackup/logs
	echo "=================="
	echo "Creating Softpartition for openv.Executing command \" metainit $locked_openv -p ${_usropenvnetbackuplogsmd} ${size_for_openv}g \" "
	read -p "Press enter to continue"
	metainit $locked_openv -p ${_usropenvnetbackuplogsmd} ${size_for_openv}g     #for /usr/openv
	echo "INFO: softpartitions created "
	metastat -p $locked_nblog $locked_openv #  -- to verify if we got required ones
	echo "=================="
	echo "FS creation for nblogs. Executing command \" newfs /dev/md/rdsk/${locked_nblog}\" "
	read -p "Press enter to continue"
	newfs /dev/md/rdsk/${locked_nblog}
	echo "FS creation for openv. Executing command \"newfs /dev/md/rdsk/${locked_openv}\" "
	read -p "Press enter to continue"
	newfs /dev/md/rdsk/${locked_openv}
	echo "=================="
	cd "/usr"
	echo "INFO: Cleaning up the openv directory"
    cd "/usr/openv"; 
	rm -rf *
    cd "/"
    [ $? -ne 0 ] && (echo "Unable to cleanup openv. mounting of openv might fail")
	umask 022;
    [ ! -d /usr/openv ] && mkdir /usr/openv; 
    cd "/"

	echo "Mounting filesystems.."

	mount -f ufs /dev/md/dsk/${locked_openv}  ${BASEDIR} 
	[ $? -ne 0 ] && (echo "Unable to mount FS, exiting.." ) && exit 4
	echo "INFO: recreating /usr/openv/netbackup/logs directory"
	mkdir -p /usr/openv/netbackup/logs
	echo "INFO: mounting /usr/openv/netbackup/logs.."
	mount ${BASEDIR_LOG}
	[ $? -ne 0 ] && echo "Unable to mount FS, exiting.." && exit 4 || RC=0
    
}

untar_and_start_NB () {

	#Untaring

	 if [[ -f "${_available_mnt}/${BASE_TAR}" ]] ; then
 
        cd ${BASEDIR}
	echo "INFO: Restoring the openv data from backup.."
        tar -xf ${_available_mnt}/${BASE_TAR}
	echo "SUCCESS: openv data restored"
    fi 

	echo "INFO: Atempting to bring up NB process....."

    "/opt/VRTSpbx/bin/vxpbx_exchanged" start > /dev/null 2>&1
    sleep 1

    "/usr/openv/netbackup/bin/goodies/netbackup" start > /dev/null 2>&1
    sleep 1

     if [[ $(/usr/openv/netbackup/bin/bpps -x|awk '/vnetd/||/bpcd/||/pbx/ {print $8$9}'|wc -l) -le 4 ]] ; then 
         
         echo "SUCCESS: NB Process started up successfully :)"
         RC=0
     else
        echo "INFO: Unable to start NB process.Please start manually"
        RC=19
     fi
}



#MAIN

go_no-go 
if [ $RC -ne 0 ]; then
	echo "didnt match the scenarion 1. Exiting.."
	exit 15
fi
echo "=================="
NB_shutdown 
NB_shutdown
if [ $RC -ne 0 ]; then
	echo "unable to shutdown NB processess. Exiting.."
	exit 17
fi
echo "=================="
backup_core_files
if [ $RC -ne 0 ] ; then
	echo "unable to take backup. Exiting.."
	exit 14
fi
echo "=================="
basix_math
echo "=================="
_output=failed
sp_for_logs=`echo ${_usropenvnetbackuplogssp}|tr -d '[[:alpha:]]'`
sp_for_openv=$sp_for_logs

while [[ $_output == failed ]]; do
	let sp_for_openv=sp_for_openv+1
	_output=`free_sp_identifier ${sp_for_openv}`
	#let sp_for_openv=sp_for_openv+1
done

echo "=================="
locked_nblog=${_usropenvnetbackuplogssp}
locked_openv=d$sp_for_openv
echo "md name which is going to use for NBLOGS is - $locked_nblog"
echo "md name which is going to use for OPENV is - $locked_openv"


metastat -p|awk '{print $1}'

echo " Are you sure that there are no duplicate meta device exists with the identified new names for NBLOGS and OPENV?"

read -p "Press enter to continue" 

echo "checking open files and killing open NB process"


read -p "Press enter to continue" 

echo "=================="
nb_softslice_relayout
echo "=================="
if [ $RC -ne 0 ] ; then
	echo "Failed at soft slice creation.."
	exit 21
fi
echo "=================="
untar_and_start_NB 

#_END_
