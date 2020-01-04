#!/bin/bash
# must pass the touch directory absolute path when exeucting script
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
# must pass the destination user, ip, and absoulte path when executing script
rsync --remove-source-files -av $TAR $2 --log-file=$LOGFILE
echo " " >> $LOGFILE