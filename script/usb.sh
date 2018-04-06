#!/bin/bash

#Function to check if the time is during working hours
function workingHours()
{
    now=$(date +%H:%M)
    if [[ "$now" < "15:00" ]] && [[ "$now" > "13:00" ]]; then
            return 0;
    else
            return 1;
    fi
}

# Mount locations
primary="/mnt/primary"
backup="/mnt/backup"

# Create directories
if ! [ -d "$primary" ]; then
    mkdir -p "$primary"
fi

if ! [ -d "$backup" ]; then
    mkdir -p "$backup"
fi

# If primary is not mounted, mount it
if ! mount | grep $primary > /dev/null 2>&1; then
    mount LABEL=PRIMARY "$primary" > /dev/null 2>&1
fi

# If primary is mounted, sync
if mount | grep $primary > /dev/null 2>&1; then
    rsync -rltDqzPcO --no-perms --backup-dir=old /home/pi/data "$primary"
fi

# If is not working hours and backup is not mounted, mount it
if ! workingHours && ! mount | grep $backup > /dev/null 2>&1; then
    mount LABEL=BACKUP "$backup" > /dev/null 2>&1
fi

# If the backup is mounted, sync
if  mount | grep $backup > /dev/null 2>&1; then
    rsync -rltDqzPcO --no-perms --backup-dir=old /home/pi/data "$backup"
    umount LABEL=BACKUP "$backup" > /dev/null 2>&1
fi
