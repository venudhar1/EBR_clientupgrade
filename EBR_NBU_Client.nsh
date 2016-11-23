#!/bin/zsh



PLATFORM=$(nexec -e uname)
HNAME=$(nexec -e "uname -n")
echo $HNAME
DATE=$(date "+%d%m%y %H:%M")
VERSION=$( nexec -e uname -r)

BASEDIR=/usr/openv
TEMP_VAR=/var/tmp
TEMP_CRASH=/var/crash
TEMP_SWAP=/tmp
MAGICNUMBER=2097153


#IDENTIFY PLATFORM


platform_identifier () {
	if [ $PLARFORM = SunOS ]; then
		if [ $VERSION = "5.10" ] then
			echo "INFO: $PLATFORM with version $VERSION"
		else echo "INFO: $PLATFORM with version $VERSION"
		fi
	elif [ $PLARFORM = Linux ]; then
		echo "INFO: $PLATFORM with version $VERSION"
	elif [ $PLARFORM = HP-UX ]; then
		echo "INFO: $PLATFORM with version $VERSION"
	else
	echo "ERROR: $PLATFORM unidentified"
	fi

disk_analyser () {

if [ $PLATFORM = HP-UX ] ; then
	bdf / /var /var/tmp /usr/openv 	
	
	
