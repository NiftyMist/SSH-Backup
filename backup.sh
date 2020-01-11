#!/bin/bash

# must pass the touch directory absolute path when exeucting script as $1

START=`date +s`

DATE=`date "+%Y-%m-%d"`

TARBALL="/tmp/backup-$DATE.tar.gz"

LOGDIR="/var/log/scripts"

LOGFILE="/var/log/scripts/backup-script.log"

if [ ! -d "$LOGDIR" ] 
then
    /bin/mkdir "$LOGDIR"
    /usr/bin/touch "$LOGFILE"
fi

echo "$DATE" >> "$LOGFILE"
LOGTIME=`date "+%Y-%m-%d %H:%M"`
echo "$LOGTIME - Creating the tarball"
/bin/tar czf "$TARBALL" "$1" 2> "$LOGFILE"

# must pass the destination user, ip, and absoulte path when executing script as $2

LOGTIME=`date "+%Y-%m-%d %H:%M"`
echo "$LOGTIME - Starting the RSYNC"
echo "rsync --remove-source-files -av $TAR $2 --log-file=$LOGFILE"
echo " " >> "$LOGFILE"

END=`date +s`

RUNTIME=$((END-START))
MINUTES=$((RUNTIME / 60))
echo "Script completed in $MINUTES minutes." >> "$LOGFILE"
echo " " >> "$LOGFILE"
echo " ############ " >> "$LOGFILE"
echo " " >> $LOGFILE