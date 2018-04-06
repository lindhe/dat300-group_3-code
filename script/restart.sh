#!/bin/bash

path=$1
offset=$2

if ! [ -s $path ]; then
    exit 1
fi

now=$(date +%s)
lastline=$(tail $path | grep "." | tail -1)
lastts=$(echo "$lastline" | grep -oP '^\d+')

if [ -z $lastts ]; then
    exit 1
fi

tswithoffset=$(($lastts + $offset))
if [ $now -gt $tswithoffset ]; then
    echo "Restart $now"
    #reboot
fi
