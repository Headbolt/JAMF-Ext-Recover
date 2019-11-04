#!/bin/bash
#
###############################################################################################################################################
#
#   This Script is designed for use in JAMF as an Extension Attribute
#
#   - This script will ...
#       Look at the Machines OS Version and use it to check in the correct
#	location for a Recovery Partition
#
###############################################################################################################################################
#
# HISTORY
#
#   Version: 1.2 - 04/11/2019
#
#   - 14/10/2018 - V1.0 - Created by Headbolt
#
#   - 01/04/2019 - V1.1 - Updated by Headbolt
#				Updated for Mojave
#   - 04/11/2019 - V1.2 - Updated by Headbolt
#				Updated for Catalina and later by checking for the 
#				crossover points rather than individual OS Versions
#
###############################################################################################################################################
#
OS_ver=$(sw_vers | grep ProductVersion | cut -c 17-) # Get the OS we're on
MajorVer=$(/bin/echo "$OS_ver" | awk -F. '{ print $1; }') # Split Out Major Version
MinorVer=$(/bin/echo "$OS_ver" | awk -F. '{ print $2; }') # Split Out Minor Version
PatchVer=$(/bin/echo "$OS_ver" | awk -F. '{ print $3; }') # Split Out Patch Version
#
if [[ "${MinorVer}" -lt 12 ]] # Check Minor Version is Sierra or Lower
	then
		disk=0 # If Sierra or Lower we need to look at Disk 0
	else
		disk=1 # If High Sierra or Higher we need to look at Disk 1
fi
#
# Check for Relevant Recovery Partition
recoveryHDPresent=$(/usr/sbin/diskutil list | grep "Recovery" | grep $disk) 
#
if [ "$recoveryHDPresent" != "" ] # Check and Output presence of Recovery Partition
	then
		/bin/echo "<result>Present</result>"
	else
		/bin/echo "<result>Not Present</result>"
fi    
