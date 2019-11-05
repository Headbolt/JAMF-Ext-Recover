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
#   Version: 1.4 - 05/11/2019
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
#   - 05/11/2019 - V1.4 - Updated by Headbolt
#							Updated Again to remove Version based Disk Number and instead allow setting
#							a variable to specify a number of disks to check and cycle through them all.
#							this was to accomodate varying configurations of Hardware etc
#
###############################################################################################################################################
#
#   DEFINE VARIABLES & READ IN PARAMETERS
#
###############################################################################################################################################
#
# Determine what you wish to report
# MATCH = If Present, does the Recovery Partition Match the OS Version
# VER = If Present, what is the Recovery Partition Version
MATCH_VER=VER
Disks_To_Check=5 # Set Number Of Disks to be Checked. eg. 5 + Disks 0 to 5
#
OS_ver=$(sw_vers | grep ProductVersion | cut -c 17-) # Get the OS we're on
OS_MajorVer=$(/bin/echo "$OS_ver" | awk -F. '{ print $1; }') # Split Out Major Version
OS_MinorVer=$(/bin/echo "$OS_ver" | awk -F. '{ print $2; }') # Split Out Minor Version
OS_PatchVer=$(/bin/echo "$OS_ver" | awk -F. '{ print $3; }') # Split Out Patch Version
#
Disk_Array=$(seq -s ' ' 0 $Disks_To_Check) 
#
###############################################################################################################################################
# 
# SCRIPT CONTENTS - DO NOT MODIFY BELOW THIS LINE
#
###############################################################################################################################################
#
# Defining Functions
#
###############################################################################################################################################
#
# Partition Check Function
#
RecoveryPartCheck(){
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
				RecVer=$(/usr/bin/defaults read /Volumes/"$RecoveryVolumeMountPoint"/$RecPath/SystemVersion.plist ProductVersion 2>/dev/null)
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
		#Unmount RecoveryHD
		diskutil unmount "$recoveryPartition" >/dev/null
		#
        if [ $MATCH_VER == "MATCH" ]
			then
				if [[ "${BestRecVer}" == "${OS_ver}" ]]      
					then
						Result="MATCH"
					else
						Result="NO MATCH"
				fi
			else
				Result=$BestRecVer
		fi
	else
		Result="Not Present"
fi
#
}
#
###############################################################################################################################################
#
# End Of Function Definition
#
###############################################################################################################################################
# 
# Begin Processing
#
###############################################################################################################################################
#
for Count in $Disk_Array
	do
		disk=disk$Count
        RecoveryPartCheck
		BestRecFinalVer="0"
		#
		if [[ "${BestRecFinalVer}" == "0" ]]
			then
				BestRecFinalVer=$BestRecVer
			else
				BestRecFinalMajorVer=$(/bin/echo "$BestRecFinalVer" | awk -F. '{ print $1; }') # Split Out Major Version
				BestRecFinalMinorVer=$(/bin/echo "$BestRecFinalVer" | awk -F. '{ print $2; }') # Split Out Minor Version
				BestRecFinalPatchVer=$(/bin/echo "$BestRecFinalVer" | awk -F. '{ print $3; }') # Split Out Patch Version
				#
				if [[ "${BestRecFinalMajorVer}" -le "${BestRecMajorVer}" ]]
					then
						if [[ "${BestRecFinalMinorVer}" -le "${BestRecMinorVer}" ]]
							then	
								if [[ "${BestRecFinalPatchVer}" -le "${BestRecPatchVer}" ]]
									then
										BestRecFinalVer=$BestRecVer
								fi
						fi
				fi
		fi
		#
		if [ $MATCH_VER == "MATCH" ]
			then
				if [ "$Result" == "NO MATCH" ]
					then
						if [ "$Final_Result" == "MATCH" ]
							then
								Final_Result=$Final_Result
							else
								Final_Result=$Result
						fi
					else
						if [ "$Final_Result" == "MATCH" ]
							then
								Final_Result=$Final_Result
							else
								Final_Result=$Result
						fi
				fi
			else
				if [[ "${BestRecFinalVer}" != "0" ]]
					then
						Final_Result=$BestRecFinalVer
					else
						Final_Result="Not Present"
				fi    
		fi
done
#
/bin/echo "<result>$Final_Result</result>"
