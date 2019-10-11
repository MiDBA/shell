#!/bin/ksh
#set -x

# Take system snapshot
DL="lowej5@michigan.gov"

export PATH=$PATH:/usr/sbin
export RUNDATE=$(date "+%Y%m%d%H%M")
HOSTNAME=`hostname`
NODE=${HOSTNAME: -1}
export CALLING_PROC=$(basename ${0})
export SCRIPTDIR=$(dirname ${0})
export LOGDIR=$SCRIPTDIR/logs
export LOG=$LOGDIR/$HOSTNAME.snapshot.$RUNDATE
cd $SCRIPTDIR

REFLOG=`ls -t1 $LOGDIR/$HOSTNAME* | head -n 1`
echo Reference Log: $REFLOG


./system_snapshot.sh > $LOG 2>&1

echo "diff $REFLOG $LOG"
DIFFRES=`diff $REFLOG $LOG`

if [[ "$DIFFRES" ]]; then
        echo Emailing Differences Found
        diff $REFLOG $LOG > difftmp.dat
        echo "To: $DL">mailheader
        echo "Subject: SYSTEM ALERT $HOSTNAME $RUNDATE">>mailheader
        echo "Content-Type: text/plain">>mailheader
        cat difftmp.dat >>mailheader
        #echo $DIFFRES >>mailheader
        cat mailheader | sendmail -t

else
        echo No Differences Found
fi

#Cleanup

echo "find $LOGDIR -mtime +30 -exec rm {} \;"
find $LOGDIR -mtime +30 -exec rm {} \;
