#!/bin/bash

# Due to a velero bug, a backup is created anytime the backup schedule is created or updated.
# Backups should only occurs based upon the cron schedule and not when the schedule itself is created.. 
# This bug can result in a backup being created before the service is fully running and thus the backup ends up PartiallyFailed.
# A cleanup is done for any PartiallyFailed backup that exists for backups that were created within 10 minutes of the schedule being created.

cleanup_velero_backups() {

    ten_minutes=600 # in seconds

    # Get the list of backup schedule names.
    velero_schedule_names=$(velero schedule get | grep -v NAME | awk '{print $1}')

    # Check it any backup schedules exist
    if [[ ! -z ${velero_schedule_names} ]]
    then
        for schedule_name in ${velero_schedule_names}
        do
	    delete_count=0
            echo ""
            echo "schedule_name: ${schedule_name}"

            schedule_creation_date=$(velero schedule get "${schedule_name}" -o json | jq -r '.metadata.creationTimestamp')
  
            echo "schedule_creation_date: ${schedule_creation_date}"

           velero_partiallyfailed_backups=$(kubectl get backups -A -o json | jq -r ".items[] | select(.metadata.name | contains(\"${schedule_name}\")) | select(.status.phase == \"PartiallyFailed\") | .metadata.name")
           
            echo "velero_partiallyfailed_backups: "
	    [[ -z $velero_partiallyfailed_backups ]] && echo "None" || echo "${velero_partiallyfailed_backups}"

	    # Check if any PartiallyFailed backups exist 
            if [[ ! -z ${velero_partiallyfailed_backups} ]]
            then
                for backup_name in ${velero_partiallyfailed_backups}
                do

                    backup_creation_date=$(kubectl get backups -A -o json | jq -re ".items[] | select (.metadata.name == \"${backup_name}\") | .metadata.creationTimestamp")
                    schedule_creation_date_sec=$(date -d "${schedule_creation_date}" +%s)
                    backup_creation_date_sec=$(date -d "${backup_creation_date}" +%s)
                 
                    # Check if the PartiallyFailed backup occured within 10 minutes after the schedule was created. If so delete the backup.

                    time_from_schedule_creation_to_backup=$(( $backup_creation_date_sec - $schedule_creation_date_sec ))
                    if [[ ! -z $backup_creation_date_sec && ${time_from_schedule_creation_to_backup} -ge 0 && ${time_from_schedule_creation_to_backup} -lt $ten_minutes ]]
                    then
                        delete_count+=1
		        echo "velero backup delete ${backup_name}"
	                velero backup delete ${backup_name} --confirm
                    fi
               done
	   fi

	   [[ $delete_count -eq 0 ]] && echo "No PartiallyFailed backups for ${schedule_name} were deleted"


       done
    fi
}

cleanup_velero_backups

kubectl get backups -A -o json | jq '.items[].status.phase' | grep "Failed"
if [[ $? -eq 0 ]]; 
then 
    echo "Investigate remaining Failed or PartiallyFailed backups: $(kubectl get backups -A -o json | jq -e '.items[] | select(.status.phase == "PartiallyFailed") | .metadata.name')"
    echo "FAIL"; exit 1;
else 
    echo "PASS"; exit 0;
fi
