#!/bin/bash

# adjustable vars
SOURCE="/zfs/home-share"

REMOTE_USER="root"

REMOTE_HOST="bak01.niftymist.us"

REMOTE_DIR="/zfs-backup/offsite/home-share/"

REMOTE_PARITION="/zfs-backup/offsite"
# end adjustable vars

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

# check remote disk space
REMOTE_DISK_SPACE=`ssh $REMOTE_USER@$REMOTE_HOST df -Ph /zfs-bakup/offsite | tail -n 1 | awk '{ print $5 }'`
LOGTIME=`date "+%Y-%m-%d %H:%M"`
if [ "{$REMOTE_DISK_SPACE::01}" -gt 80 ]
then 
    echo "$LOGTIME - remote disk space check passed with $REMOTE_DISK_SPACE" >> "$LOGFILE"
else
    echo "$LOGIMTE - remote disk space check failed with $REMOTE_DISK_SPACE, stopping backup" >> "$LOGFILE"
    exit 1
fi

LOGTIME=`date "+%Y-%m-%d %H:%M"`
echo "$LOGTIME - Creating the tarball for $SOURCE at $TARBALL" >> "$LOGFILE"
/bin/tar czf "$TARBALL" --absolute-names "$SOURCE" 2> "$LOGFILE"

LOGTIME=`date "+%Y-%m-%d %H:%M"`
echo "$LOGTIME - Starting the RSYNC to $REMOTE_HOST" > "$LOGFILE"
/usr/bin/rsync --remove-source-files -av $TARBALL $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR --log-file=$LOGFILE
echo " " >> "$LOGFILE"
END=`date +%s`
RUNTIME=$((END-START))
MINUTES=$((RUNTIME / 60))
LOGTIME=`date "+%Y-%m-%d %H:%M"`
echo "$LOGTIME - Script completed in $MINUTES minutes." >> "$LOGFILE"