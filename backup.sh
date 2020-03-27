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

LOGTIMEFUN () {
    LOGTIME=`date "+%Y/%m/%d %H:%M:%S"`
    echo "$LOGTIME $1" | tee -a $LOGFILE
}

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
    LOGTIMEFUN "- remote disk space check passed with $REMOTE_DISK_SPACE"
else
    LOGTIMEFUN "- remote disk space check failed with $REMOTE_DISK_SPACE, stopping backup"
    exit 1
fi

REMOTE_FILES_TO_REMOVE=( $(ssh $REMOTE_USER@$REMOTE_HOST find $REMOTE_DIR -type f -name '*.tar.gz' -mtime +30) )
if [ ${#REMOTE_FILES_TO_REMOVE[@]} -gt 0 ]
then
    for i in ${REMOTE_FILES_TO_REMOVE[@]}
    do
        LOGTIMEFUN "- $REMOTE_FILES_TO_REMOVE is older than 30 days...  deleting"
        ssh $REMOTE_USER@$REMOTE_HOST rm -rf $REMOTE_FILES_TO_REMOVE
    done
fi

LOGTIMEFUN "- creating the tarball for $SOURCE at $TARBALL"
/bin/tar -I pbzip2 -cf "$TARBALL" --absolute-names "$SOURCE" 2>> "$LOGFILE"

LOGTIMEFUN "- starting the RSYNC to $REMOTE_HOST" >> "$LOGFILE"
/usr/bin/rsync --remove-source-files --stats -hav $TARBALL $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR
echo " " >> "$LOGFILE"
END=`date +%s`
RUNTIME=$((END-START))
MINUTES=$((RUNTIME / 60))

LOGTIMEFUN "- script completed in $MINUTES minutes."