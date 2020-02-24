#!/bin/bash

# adjustable vars
SOURCE="/zfs/home-share"

REMOTE_USER="root"

REMOTE_HOST="bak01.mitchell.house"

REMOTE_DIR="/zfs-bakup/offsite/home-share/"

REMOTE_PARTITION="/zfs-bakup/offsite"
# end adjustable vars

START=`date +%s`

DATE=`date "+%Y-%m-%d"`

TARBALL="/tmp/backup-$DATE.tbz"

LOGDIR="/var/log/scripts"

LOGFILE="/var/log/scripts/backup-script.log"

if [ ! -d "$LOGDIR" ] 
then
    /bin/mkdir "$LOGDIR"
    /usr/bin/touch "$LOGFILE"
fi

# check remote disk space
REMOTE_DISK_SPACE=`ssh $REMOTE_USER@$REMOTE_HOST df -Ph $REMOTE_PARTITION | tail -n 1 | awk '{ print $5 }'`
SPACE=${REMOTE_DISK_SPACE::-1}
if [ "$SPACE" -lt 80 ]
then 
    LOGTIME=`date "+%Y/%m/%d %H:%M:%S"`
    echo "$LOGTIME - remote disk space check passed with $REMOTE_DISK_SPACE" >> "$LOGFILE"
else
    LOGTIME=`date "+%Y/%m/%d %H:%M:%S"`
    echo "$LOGTIME - remote disk space check failed with $REMOTE_DISK_SPACE, stopping backup" >> "$LOGFILE"
    exit 1
fi

REMOTE_FILES_TO_REMOVE=( $(ssh $REMOTE_USER@$REMOTE_HOST find $REMOTE_DIR -type f -name '*.tar.gz' -mtime +30) )
if [ ${#REMOTE_FILES_TO_REMOVE[@]} -gt 0 ]
then
    for i in ${REMOTE_FILES_TO_REMOVE[@]}
    do
        LOGTIME=`date "+%Y/%m/%d %H:%M:%S"`
        echo "$LOGTIME - $REMOTE_FILES_TO_REMOVE is older than 30 days...  deleting" >> "$LOGFILE"
        ssh $REMOTE_USER@$REMOTE_HOST rm -rf $REMOTE_FILES_TO_REMOVE
    done
fi

LOGTIME=`date "+%Y/%m/%d %H:%M:%S"`
echo "$LOGTIME - creating the tarball for $SOURCE at $TARBALL" >> "$LOGFILE"
/bin/tar -I pbzip2 -cf "$TARBALL" --absolute-names "$SOURCE" 2>> "$LOGFILE"

LOGTIME=`date "+%Y/%m/%d %H:%M:%S"`
echo "$LOGTIME - starting the RSYNC to $REMOTE_HOST" >> "$LOGFILE"
/usr/bin/rsync --remove-source-files --stats -hav $TARBALL $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR >> "$LOGFILE"
echo " " >> "$LOGFILE"
END=`date +%s`
RUNTIME=$((END-START))
MINUTES=$((RUNTIME / 60))
LOGTIME=`date "+%Y/%m/%d %H:%M:%S"`
echo "$LOGTIME - script completed in $MINUTES minutes." >> "$LOGFILE"