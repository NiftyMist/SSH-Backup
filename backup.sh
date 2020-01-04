#!/bin/bash
# must pass the touce directory absolute path when exeucting script
DATE=`date "+%Y-%m-%d"`
TAR="/tmp/backup-$DATE.tar.gz
LOGDIR="/var/log/scripts"
LOGFILE="/var/log/scripts/backup-script.log"
if [ ! -d "$LOGDIR ]; then
    /bin/mkdir $LOGDIR
    /usr/bin/touch $LOGFILE
fi
/bin/tar czvf $TAR $1
rsync --remove-source-files -av $TAR $2 --log-file=$LOGFILE