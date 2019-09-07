#!/bin/bash
# This command needs to be send to toggle the Sonoff device to on.

# Configuration file
source /home/pi/sunset/config

/usr/bin/curl --data "$command1" "$url1"

exit
