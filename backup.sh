#!/bin/bash

# must pass the source directory's absolute path when exeucting script as $1

START=`date +%s`

DATE=`date "+%Y-%m-%d"`

TARBALL="/tmp/backup-$DATE.tar.gz"

LOGDIR="/var/log/scripts"

LOGFILE="/var/log/scripts/backup-script.log"

if [ ! -d "$LOGDIR" ] 
then
    /bin/mkdir "$LOGDIR"
    /usr/bin/touch "$LOGFILE"
fi

#check remote disk space
REMOTE_DISK_SPACE=`ssh root@bak01.niftymist.us df -Ph /zfs-bakup/offsite | tail -n 1 | awk '{ print $5 }'`
LOGTIME=`date "+%Y-%m-%d %H:%M"`
if [ "{$REMOTE_DISK_SPACE::01}" -gt 80 ]
then 
    echo "$LOGTIME - remote disk space check passed with $REMOTE_DISK_SPACE" >> "$LOGFILE"
else
    echo "$LOGIMTE - remote disk space check failed with $REMOTE_DISK_SPACE, stopping backup" >> "$LOGFILE"
    exit 1
fi

LOGTIME=`date "+%Y-%m-%d %H:%M"`
echo "$LOGTIME - Creating the tarball for $1 at $TARBALL" >> "$LOGFILE"
/bin/tar czf "$TARBALL" --absolute-names "$1" 2> "$LOGFILE"

# must pass the destination user, ip, and absoulte path when executing script as $2

LOGTIME=`date "+%Y-%m-%d %H:%M"`
echo "$LOGTIME - Starting the RSYNC to $2" > "$LOGFILE"
/usr/bin/rsync --remove-source-files -av $TARBALL $2 --log-file=$LOGFILE
echo " " >> "$LOGFILE"
END=`date +%s`
RUNTIME=$((END-START))
MINUTES=$((RUNTIME / 60))
LOGTIME=`date "+%Y-%m-%d %H:%M"`
echo "$LOGTIME - Script completed in $MINUTES minutes." >> "$LOGFILE"