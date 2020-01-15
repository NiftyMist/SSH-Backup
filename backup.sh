#!/bin/bash

# adjustable vars
SOURCE="/zfs/home-share"

REMOTE_USER="root"

REMOTE_HOST="bak01.niftymist.us"

REMOTE_DIR="/zfs-bakup/offsite/home-share/"

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

LOGTIME=`date "+%Y/%m/%d %H:%M:%S"`
echo "$LOGTIME - creating the tarball for $SOURCE at $TARBALL" >> "$LOGFILE"
/bin/tar -I pigz -cf "$TARBALL" --absolute-names "$SOURCE" 2> "$LOGFILE"

LOGTIME=`date "+%Y/%m/%d %H:%M:%S"`
echo "$LOGTIME - starting the RSYNC to $REMOTE_HOST" >> "$LOGFILE"
/usr/bin/rsync --remove-source-files -av $TARBALL $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR --log-file=$LOGFILE
echo " " >> "$LOGFILE"
END=`date +%s`
RUNTIME=$((END-START))
MINUTES=$((RUNTIME / 60))
LOGTIME=`date "+%Y/%m/%d %H:%M:%S"`
echo "$LOGTIME - script completed in $MINUTES minutes." >> "$LOGFILE"