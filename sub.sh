#!/bin/bash
# Custom script for turning on and off the garden security lights by Buq 2019

# Configuration file
source /home/pi/sunset/config

# Choose one of the methods below to get grab the information from weather.com
# sun_times=$( lynx --dump  https://weather.com/weather/today/l/$location | grep "\* Sun" | sed "s/[[:alpha:]]//g;s/*//" )
#sun_times=$( curl -s  https://weather.com/weather/today/l/$location | sed 's/<span/\n/g' | sed 's/<\/span>/\n/g'  | grep -E "dp0-details-sunrise|dp0-details-sunset" | tr -d '\n' | sed 's/>/ /g' | cut -d " " -f 4,8 )
sun_times=$( wget -qO-  https://weather.com/weather/today/l/$location | sed 's/<span/\n/g' | sed 's/<\/span>/\n/g'  | grep -E "dp0-details-sunrise|dp0-details-sunset" | tr -d '\n' | sed 's/>/ /g' | cut -d " " -f 4,8 )

# Remove the previous log file
if [ -f $file ] ; then
    rm $file
fi

# Create a new log file
/usr/bin/touch $file

# give the system some time to complete the writing
sleep 1

# Some output to the logfile
echo "Logfile started on $now" >> $file 2>&1
echo "Getting new information from weather.com" >> $file 2>&1
echo "Using location number: $location" >> $file 2>&1

# Extract sunrise and sunset times and convert to 24 hour format
sunrise=$(date --date="`echo $sun_times | awk '{ print $1}'` AM" +%R)
sunset=$(date --date="`echo $sun_times | awk '{ print $2}'` PM" +%R)

# We need to know sure if the variable is not empty and trigger a fallback in case its empty.
if [ -z "$sunrise" ] 
then
	# Fall back on the fixed sunrise time when the resource is unavailable.
	sunrise="$fb_sunrise"
	echo "Warning no new timestamp recieved!" >> "$file" 2>&1
	echo "Falling back on default sunrise time: $fb_sunrise" >> "$file" 2>&1
else
	echo "Online sunrise timestamp check, ok" >> "$file" 2>&1
fi

if [ -z "$sunset" ] 
then
        # Fall back on the fixed sunrise time when the resource is unavailable.
        sunset="$fb_sunset"
        echo "Warning no new timestamp recieved!" >> "$file" 2>&1
        echo "Falling back on default sunset time: $fb_sunset" >> "$file" 2>&1
else
        echo "Online sunset timestamp check, ok" >> "$file" 2>&1
fi

#Update the logfile with the new timestamps
echo "Sunrise is set on: $sunrise" >> $file 2>&1
echo "Sunset is set on: $sunset" >> $file 2>&1

#Convert the sunrise time string to an array.
STR_SUNRISE="$sunrise"
IFS=':' read -ra SR <<< "$STR_SUNRISE"

#Building up the cron for sunrise:
croncmd_rise="/home/pi/sunset/sunrise.sh"
cronjob_rise="${SR[1]} ${SR[0]} * * * $croncmd_rise"

echo "Cronjob for sunrise: $cronjob_rise" >> $file 2>&1
# Delete to old rise command entry from crontab
( /usr/bin/crontab -l | grep -v -F "$croncmd_rise" ) | /usr/bin/crontab -
# Update the crontab with a new timestamp and rise command
( /usr/bin/crontab -l | grep -v -F "$croncmd_rise" ; echo "$cronjob_rise" ) | /usr/bin/crontab -

#Convert the sunrise time string to an array.
STR_SUNSET="$sunset"
IFS=':' read -ra SS <<< "$STR_SUNSET"

#Building up the cron for sunset:
croncmd_set="/home/pi/sunset/sunset.sh"
cronjob_set="${SS[1]} ${SS[0]} * * * $croncmd_set"

echo "Cronjob for sunset: $cronjob_set" >> $file 2>&1
# Delete to old rise command entry from crontab
( /usr/bin/crontab -l | grep -v -F "$croncmd_set" ) | /usr/bin/crontab -
# Update the crontab with a new timestamp and rise command
( /usr/bin/crontab -l | grep -v -F "$croncmd_set" ; echo "$cronjob_set" ) | /usr/bin/crontab -

# Update the logfile
echo "Finished setting up new time schedule" >> $file 2>&1

# Mail the logfile
/usr/bin/mail -s "Timetable Update" -r $email_r $email < $file

exit
