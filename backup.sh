#!/bin/bash
# must pass the touce directory absolute path when exeucting script
DATE=`date "+%Y-%m-%d"`
TARBALL="/tmp/backup-$DATE.tar.gz
LOGDIR="/var/log/scripts"
LOGFILE="/var/log/scripts/backup-script.log"
if [ ! -d "$LOGDIR ]; then
    /bin/mkdir $LOGDIR
    /usr/bin/touch $LOGFILE
fi
echo "### $DATE ###" >> $LOGFILE
/bin/tar czvf $TARBALL $1
rsync --remove-source-files -av $TAR $2 backup@10.1.2.249:/zfs-offsite/home-share/ --log-file=$LOGFILE
echo " " >> $LOGFILE