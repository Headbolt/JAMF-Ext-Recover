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
#   Version: 1.3 - 04/11/2019
#
#   - 14/10/2018 - V1.0 - Created by Headbolt
#
#   - 01/04/2019 - V1.1 - Updated by Headbolt
#							Updated for Mojave
#   - 03/11/2019 - V1.2 - Updated by Headbolt
#							Updated for Catalina and later by checking for the 
#							crossover points rather than individual OS Versions
#   - 04/11/2019 - V1.3 - Updated by Headbolt
#							Updated Again to Cycle through all instances of Recovery Partitions
#							and report the Highest Version Number as what is available
#
###############################################################################################################################################
#
OS_ver=$(sw_vers | grep ProductVersion | cut -c 17-) # Get the OS we're on
MajorVer=$(/bin/echo "$OS_ver" | awk -F. '{ print $1; }') # Split Out Major Version
MinorVer=$(/bin/echo "$OS_ver" | awk -F. '{ print $2; }') # Split Out Minor Version
PatchVer=$(/bin/echo "$OS_ver" | awk -F. '{ print $3; }') # Split Out Patch Version
#
if [[ "${MinorVer}" -le 12 ]] # Check Minor Version is Sierra or Lower
	then
		disk="disk0" # If Sierra or Lower we need to look at Disk 0
	else
		disk="disk1" # If High Sierra or Higher we need to look at Disk 1
fi
#
# Check for Relevant Recovery Partition
recoveryHDPresent=$(/usr/sbin/diskutil list | grep "Recovery" | grep $disk) 
#
if [ "$recoveryHDPresent" != "" ] # Check and Output presence of Recovery Partition
	then
		recoveryPartition=$(/bin/echo "$recoveryHDPresent" | rev | cut -c -7 | rev)
		RecoveryVolumeMountMessage=$(diskutil mount $recoveryPartition)
		RecoveryVolumeMountPoint=$(echo $RecoveryVolumeMountMessage | awk -F"on" '{ print $1; }' | cut -c 8- | rev | cut -c 2- | rev)
		RecoveryVolumeFolderList=$(ls /Volumes/"$RecoveryVolumeMountPoint"/)
		#
		BestRecVer="0"
		for RecPath in $RecoveryVolumeFolderList
			do
				# Grab the Version from this instance of Recovery
				RecVer=$(/usr/bin/defaults read /Volumes/"$RecoveryVolumeMountPoint"/$RecPath/SystemVersion.plist ProductVersion)
				RecMajorVer=$(/bin/echo "$RecVer" | awk -F. '{ print $1; }') # Split Out Major Version
				RecMinorVer=$(/bin/echo "$RecVer" | awk -F. '{ print $2; }') # Split Out Minor Version
				RecPatchVer=$(/bin/echo "$RecVer" | awk -F. '{ print $3; }') # Split Out Patch Version
				#
				if [[ "${BestRecVer}" == "0" ]]
					then
						BestRecVer=$RecVer
					else
						BestRecMajorVer=$(/bin/echo "$BestRecVer" | awk -F. '{ print $1; }') # Split Out Major Version
						BestRecMinorVer=$(/bin/echo "$BestRecVer" | awk -F. '{ print $2; }') # Split Out Minor Version
						BestRecPatchVer=$(/bin/echo "$BestRecVer" | awk -F. '{ print $3; }') # Split Out Patch Version
						#
						if [[ "${BestRecMajorVer}" -le "${RecMajorVer}" ]]
							then
								if [[ "${BestRecMinorVer}" -le "${RecMinorVer}" ]]
									then	
										if [[ "${BestRecPatchVer}" -le "${RecPatchVer}" ]]
											then
												BestRecVer=$RecVer
										fi
								fi
						fi
				fi
			done
		#
		/bin/echo "<result>$BestRecVer</result>"
	else
		/bin/echo "<result>Not Present</result>"
fi    
