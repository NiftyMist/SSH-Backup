#!/bin/bash

START=`date +%s`

DATE=`date "+%Y-%m-%d"`

TARBALL="/tmp/backup-$DATE.tbz"

LOGDIR="/var/log/scripts"

LOGFILE="/var/log/scripts/backup-script.log"

CONF="$(readlink -f $0)/backup.conf"

export $CONF

LOGTIMEFUN () {
    LOGTIME=`date "+%Y/%m/%d %H:%M:%S"`
    echo "$LOGTIME $1" | tee -a $LOGFILE
}

if [ ! -d "$LOGDIR" ] 
then
    /bin/mkdir "$LOGDIR"
    /usr/bin/touch "$LOGFILE"
fi

if [ ! -d "$CONF" ] 
then
    LOGTIMEFUN "- not config file found in $CONF"
fi

# check remote host availability
REMOTE_AVAILABILITY=`nc -z $REMOTE_HOST 22`
if [ $? == 1 ]
then
    LOGTIMEFUN "- remote host is not available, stopping backup"
    exit 1
else
    LOGTIMEFUN "- remote host is available"
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