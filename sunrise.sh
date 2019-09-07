#!/bin/bash
# This command needs to be send to toggle the Sonoff device to off.

# Configuration file 
source /home/pi/sunset/config

/usr/bin/curl --data "$command2" "$url2"

exit
